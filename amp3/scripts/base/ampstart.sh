#!/bin/bash

set -eo pipefail

echo "[Info] ampstart v3 (AMP3 container entrypoint)"

: "${AMP_AGENT_BIN:?[Error] AMP_AGENT_BIN is not set - the spire must pass the path of the mounted shard agent}"
[[ -r "${AMP_AGENT_BIN}" ]] || { echo "[Error] AMP_AGENT_BIN (${AMP_AGENT_BIN}) is missing or unreadable"; exit 101; }

# Stage a runnable copy when the mounted agent carries no exec bit (NTFS-backed mounts).
if [[ ! -x "${AMP_AGENT_BIN}" ]]; then
  echo "[Info] Mounted agent carries no exec bit; staging a runnable copy."
  staged="/tmp/amp-agent/$(basename "${AMP_AGENT_BIN}")"
  if ! mkdir -p "$(dirname "${staged}")" \
     || ! cp "${AMP_AGENT_BIN}" "${staged}" \
     || ! chmod +x "${staged}"; then
    echo "[Error] Could not stage a runnable copy of ${AMP_AGENT_BIN} at ${staged}."
    exit 101
  fi
  # A noexec /tmp would leave the copy non-executable.
  [[ -x "${staged}" ]] || { echo "[Error] Staged agent at ${staged} is still not executable (is /tmp mounted noexec?)"; exit 101; }
  AMP_AGENT_BIN="${staged}"
fi

RUN_UID="$(id -u)"
if [[ "${RUN_UID}" == "0" && "${AMP_HOST_OS:-linux}" != "windows" ]]; then
  # Expected on Windows, where the container uid has no bearing on host ownership.
  echo "[Warn] Running as uid 0. Expected an unprivileged uid matching the host amp user (--userns=keep-id)."
fi

# HOME is a bind mount the spire prepared; per-user state must persist across launches.
if [[ -z "${HOME:-}" ]]; then
  echo "[Error] HOME is not set - the spire must pass it (and mount it)."
  exit 102
fi
if ! mkdir -p "${HOME}" 2>/dev/null || [[ ! -w "${HOME}" ]]; then
  echo "[Error] HOME (${HOME}) is missing or not writable. Expected a read-write bind mount."
  exit 103
fi

# XDG_RUNTIME_DIR for Wine/Proton; /run is root-owned, so fall back to a temp dir.
XDG_RUNTIME_DIR="/run/user/${RUN_UID}"
if ! install -d -m 0700 "${XDG_RUNTIME_DIR}" 2>/dev/null; then
  XDG_RUNTIME_DIR="$(mktemp -d)"
  echo "[Info] /run/user is not writable; using ${XDG_RUNTIME_DIR} for XDG_RUNTIME_DIR."
fi

# Clean environment; the bootstrap on stdin passes through untouched.
echo "[Info] Starting shard agent as uid ${RUN_UID}: ${AMP_AGENT_BIN}"
# AMP_EXTRA_PATH: a specialised image's toolchain, first so it wins.
keep_env=(
  HOME="${HOME:-/home/amp}"
  LANG="${LANG:-en_US.UTF-8}" LANGUAGE="${LANGUAGE:-en_US:en}" LC_ALL="${LC_ALL:-en_US.UTF-8}"
  PATH="${AMP_EXTRA_PATH:+${AMP_EXTRA_PATH}:}/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
  XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR}"
  AMP_CONTAINER=1
)
# Passthrough from the spire, when set.
for v in AMP_AGENT_DEBUG AMP_INSTANCE_ID AMP_SPIRE_NAME TZ; do
  if [[ -n "${!v-}" ]]; then keep_env+=("$v=${!v}"); fi
done
# AMP_ADDITIONAL_ENV_VARS: names a specialised image wants to survive env -i.
if [[ -n "${AMP_ADDITIONAL_ENV_VARS-}" ]]; then
  for v in ${AMP_ADDITIONAL_ENV_VARS}; do
    if [[ -n "${!v-}" ]]; then keep_env+=("$v=${!v}"); fi
  done
fi

exec env -i "${keep_env[@]}" "${AMP_AGENT_BIN}"
