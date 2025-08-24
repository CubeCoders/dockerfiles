#!/bin/bash

set -e -o pipefail

echo "[Info] AMPStart for Docker"
ARCH=$(uname -m)

# Context check
[ -z "${AMPUSERID}" ] && { echo "[Error] This docker image cannot be used directly by itself - it must be started by ampinstmgr"; exit 100; }

# Create /etc/machine-id (addresses Proton/dbus issues)
mkdir -p /var/lib/dbus
rm -f /etc/machine-id /var/lib/dbus/machine-id
dbus-uuidgen --ensure=/etc/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Set up amp user and group
: "${AMPUSERID:?[Error] AMPUSERID not set}"
: "${AMPGROUPID:?[Error] AMPGROUPID not set}"
echo "[Info] Setting up amp user and group..."
getent group "${AMPGROUPID}" >/dev/null 2>&1 || groupadd -r -g "${AMPGROUPID}" amp
id -u amp >/dev/null 2>&1 || useradd -m -d /home/amp -s /bin/bash -c "AMP Process User" -u "${AMPUSERID}" -g "${AMPGROUPID}" amp
usermod -aG tty amp
touch /home/amp/.gitconfig
chown -R amp:amp /home/amp 2>/dev/null

# Make AMP binary executable
[ -f /AMP/AMP_Linux_${ARCH} ] && chmod +x /AMP/AMP_Linux_${ARCH}

# Install extra dependencies if needed
REQUIRED_DEPS=()
if [[ -n "${AMP_CONTAINER_DEPS:-}" ]]; then
    # shellcheck disable=SC2207
    REQUIRED_DEPS=($(jq -r '.[]? | select(type=="string" and length>0)' <<<"${AMP_CONTAINER_DEPS}" || echo))
fi
if ((${#REQUIRED_DEPS[@]})); then
    echo "[Info] Installing extra dependencies..."
    apt-get update
    apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends --allow-downgrades "${REQUIRED_DEPS[@]}"
    apt-get clean
    rm -rf /var/lib/apt/lists/*
fi

# Set custom mountpoint permissions if needed
if [ -n "${AMP_MOUNTPOINTS}" ]; then
    echo "[Info] Updating custom mountpoint permissions..." 
    IFS=':' read -r -a dirs <<< "${AMP_MOUNTPOINTS}"
    for dir in "${dirs[@]}"; do
        [ -n "${dir}" ] || continue
        chown -R amp:amp "${dir}"
    done
fi

# Run custom start script if it exists
if [ -f "/AMP/customstart.sh" ]; then
    echo "[Info] Running customstart.sh..."
    chmod +x /AMP/customstart.sh
    /AMP/customstart.sh
fi

# Handoff
echo "[Info] Starting AMP..."
exec su -l -s /bin/bash \
    -w AMPHOSTPLATFORM,AMP_CONTAINER,AMPMEMORYLIMIT,AMPSWAPLIMIT,AMPCONTAINERCPUS,AMP_CONTAINER_HOST_NETWORK,LANG,LANGUAGE,LC_ALL \
    amp -c '
        set -e
        cd /AMP
        export LD_LIBRARY_PATH="/opt/cubecoders/amp:/AMP"
        ampinstmgr --sync-certs
        exec "/AMP/AMP_Linux_'"${ARCH}"'" "$@"
    ' -- _ "$@"
