#!/bin/bash

set -eo pipefail

echo "[Info] AMPStart for Docker"
ARCH=$(uname -m)

# Context check
[[ -z "${AMPUSERID}" ]] && { echo "[Error] This docker image cannot be used directly by itself - it must be started by ampinstmgr"; exit 100; }

# Create /etc/machine-id using the instance UUID if AMP_INSTANCE_ID exists (addresses Proton/dbus issues)
mkdir -p /var/lib/dbus
rm -f /etc/machine-id /var/lib/dbus/machine-id
if [[ -n "${AMP_INSTANCE_ID:-}" ]]; then
  printf '%s\n' "${AMP_INSTANCE_ID//-/}" > /etc/machine-id
else
  dbus-uuidgen --ensure=/etc/machine-id
fi
ln -sf /etc/machine-id /var/lib/dbus/machine-id
chmod 0444 /etc/machine-id

# Create /tmp/.X11-unix (for Xvfb etc)
install -d -o root -g root -m 1777 /tmp/.X11-unix

# Set up amp user and group
: "${AMPUSERID:?AMPUSERID not set}"
: "${AMPGROUPID:?AMPGROUPID not set}"

echo "[Info] Setting up amp user and group..."

if getent group amp >/dev/null; then
  groupmod -o -g "${AMPGROUPID}" amp
else
  groupadd -r -o -g "${AMPGROUPID}" amp
fi

if id amp &>/dev/null; then
  usermod -o -u "${AMPUSERID}" -g amp amp
else
  useradd -m -d /home/amp -s /bin/bash -c "AMP Process User" \
    -o -u "${AMPUSERID}" -g amp amp
fi

getent group tty >/dev/null && usermod -aG tty amp

install -d -m 0755 /home/amp
touch /home/amp/.gitconfig
chown amp:amp /home/amp /home/amp/.gitconfig

# Make AMP binary executable
AMP_BIN="/AMP/AMP_Linux_${ARCH}"
chmod +x "${AMP_BIN}" || { echo "[Error] AMP binary not found or cannot be made executable"; exit 101; }

# Install extra dependencies if needed (non-fatal)
REQUIRED_DEPS=()
if [[ -n "${AMP_CONTAINER_DEPS:-}" ]]; then
  # shellcheck disable=SC2207
  REQUIRED_DEPS=($(jq -r '.[]? | select(type=="string" and length>0)' <<<"${AMP_CONTAINER_DEPS}" 2>/dev/null || echo))
fi

if ((${#REQUIRED_DEPS[@]})); then
  echo "[Info] Installing extra dependencies..."
  (
    set +e
    apt-get update || echo "[Warn] apt-get update failed; continuing"
    apt-get install -y --no-install-recommends --allow-downgrades \
      -o APT::Keep-Downloaded-Packages="false" "${REQUIRED_DEPS[@]}" \
      || echo "[Warn] apt-get install failed (bad package name?); continuing"
    apt-get clean >/dev/null 2>&1 || true
    rm -rf /var/lib/apt/lists/* || true
  )
fi

# Run custom start script if it exists (non-fatal)
if [[ -f "/AMP/customstart.sh" ]]; then
  echo "[Info] Running customstart.sh..."
  chmod +x /AMP/customstart.sh 2>/dev/null || true
  ( set +e; /AMP/customstart.sh; rc=$?; ((rc==0)) || echo "[Warn] customstart.sh exited with $rc; continuing" )
fi

# Set XDG_RUNTIME_DIR (stop Wine/Proton whining)
XDG_RUNTIME_DIR="/run/user/${AMPUSERID}"
install -d -m 0700 -o amp -g amp "${XDG_RUNTIME_DIR}"

# Handoff
echo "[Info] Starting AMP..."
ARGS=$@
keep_env=(
  HOME=/home/amp
  USER=amp LOGNAME=amp SHELL=/bin/bash
  LANG="${LANG:-en_US.UTF-8}" LANGUAGE="${LANGUAGE:-en_US:en}" LC_ALL="${LC_ALL:-en_US.UTF-8}"
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
  MAIL=/var/mail/amp
  XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR}"
)
# Always keep these AMP_ env vars if set
for v in AMPHOSTPLATFORM AMP_CONTAINER AMP_CONTAINER_HOST_NETWORK AMPMEMORYLIMIT AMPSWAPLIMIT AMPCONTAINERCPUS AMP_INSTANCE_ID; do
  if [[ -n "${!v-}" ]]; then keep_env+=("$v=${!v}"); fi
done
# Extra passthrough of env vars listed in AMP_ADDITIONAL_ENV_VARS in the Dockerfile
if [[ -n "${AMP_ADDITIONAL_ENV_VARS-}" ]]; then
  for v in ${AMP_ADDITIONAL_ENV_VARS}; do
    if [[ -n "${!v-}" ]]; then keep_env+=("$v=${!v}"); fi
  done
fi

exec gosu amp:amp env -i "${keep_env[@]}" \
  bash -c "cd /AMP && exec ${AMP_BIN} ${ARGS}"
