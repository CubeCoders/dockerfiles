#!/bin/bash

set -eo pipefail

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
: "${AMPUSERID:?AMPUSERID not set}"
: "${AMPGROUPID:?AMPGROUPID not set}"

echo "[Info] Setting up amp user and group..."

if ! getent group "${AMPGROUPID}" >/dev/null; then
  if getent group amp >/dev/null; then
    groupmod -o -g "${AMPGROUPID}" amp
  else
    groupadd -r -g "${AMPGROUPID}" amp
  fi
fi

if id amp &>/dev/null; then
  usermod -o -u "${AMPUSERID}" -g "${AMPGROUPID}" amp
else
  useradd -m -d /home/amp -s /bin/bash -c "AMP Process User" \
    -u "${AMPUSERID}" -g "${AMPGROUPID}" amp
fi

getent group tty >/dev/null && usermod -aG tty amp

install -d -m 0755 /home/amp
touch /home/amp/.gitconfig
chown -R amp:amp /home/amp

# Make AMP binary executable
AMP_BIN="/AMP/AMP_Linux_${ARCH}"
[ -f "${AMP_BIN}" ] && chmod +x "${AMP_BIN}"

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
keep_env=(
  HOME=/home/amp
  USER=amp LOGNAME=amp SHELL=/bin/bash
  LANG="${LANG:-en_US.UTF-8}" LANGUAGE="${LANGUAGE:-en_US:en}" LC_ALL="${LC_ALL:-en_US.UTF-8}"
  PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
  MAIL=/var/mail/amp
)
for v in AMPHOSTPLATFORM AMP_CONTAINER AMP_CONTAINER_HOST_NETWORK AMPMEMORYLIMIT AMPSWAPLIMIT AMPCONTAINERCPUS; do
  if [[ -n "${!v-}" ]]; then keep_env+=("$v=${!v}"); fi
done

exec gosu amp:amp env -i "${keep_env[@]}" \
  bash -c 'cd /AMP && exec "$0" "$@"' "${AMP_BIN}" "$@"
