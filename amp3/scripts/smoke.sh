#!/bin/bash

set -euo pipefail

USAGE="usage: smoke.sh <image> <dockerfile> [wine_build] [wine_target]"
IMAGE="${1:?$USAGE}"
DOCKERFILE="${2:?$USAGE}"
WINE_BUILD="${3:-}"
WINE_TARGET="${4:-}"
RUNTIME="${SMOKE_RUNTIME:-docker}"

die() { echo "smoke: $*" >&2; exit 1; }

# Bash run inside the image, after the checks every image shares.
checks() {
  case "$1" in
    base/Dockerfile)
      echo "locale -a | grep -qi '^en_US\.utf8\$' && git --version && jq --version && xvfb-run --help >/dev/null && gdb --version && wg --version" ;;
    java/Dockerfile)
      echo "java -version && javac -version" ;;
    python/Dockerfile|python/Dockerfile.all)
      echo "python3 -c 'import ssl, sqlite3, ctypes, lzma, bz2' && pip3 --version" \
           "&& for p in /usr/local/bin/python3.*; do case \"\$p\" in *-config) continue;; esac; \"pip\${p#/usr/local/bin/python}\" --version; done" \
           "&& /usr/bin/python3 -m venv /tmp/v && /tmp/v/bin/python -c 'import socket'" ;;
    mono/Dockerfile)
      echo "mono --version && mcs --version" ;;
    wine/Dockerfile.common)
      echo "cabextract --version" ;;
    wine/Dockerfile)
      echo "wine --version | grep -E \"^wine-\${SMOKE_WINE_TARGET:-[0-9]+}\\.\"" \
           "&& if dpkg --compare-versions \"\${SMOKE_WINE_BUILD}\" ge 10.15; then grep -qa /dev/ntsync /opt/wine-*/bin/wineserver; fi" ;;
    apps/postgresql/Dockerfile)
      echo "gcc --version && bison --version" ;;
    apps/redis/Dockerfile)
      echo "/opt/rust-bin/rustc --version && /opt/rust-bin/cargo --version && cmake --version" ;;
    apps/uptime-kuma-2/Dockerfile)
      echo "apprise --version && cloudflared --version && mariadb --version" ;;
    apps/sinusbot/Dockerfile)
      echo "command -v x11vnc" ;;
    *)
      echo "true" ;;
  esac
}

# The image's own checks, then the real entrypoint with env standing in for the agent:
# what it prints is exactly the environment a shard agent would receive.
"$RUNTIME" run --rm --entrypoint bash \
  -e SMOKE_WINE_BUILD="$WINE_BUILD" -e SMOKE_WINE_TARGET="$WINE_TARGET" "$IMAGE" -c "
    set -euo pipefail
    tini --version
    bash -n /ampstart.sh
    if id ubuntu >/dev/null 2>&1; then echo 'uid 1000 still belongs to ubuntu' >&2; exit 1; fi
    $(checks "$DOCKERFILE")
  " </dev/null || die "the checks failed inside ${IMAGE}"
out="$("$RUNTIME" run --rm -e AMP_AGENT_BIN=/usr/bin/env -e TZ=Etc/UTC "$IMAGE" </dev/null)" \
  || die "the entrypoint of ${IMAGE} did not run the stand-in agent"
grep -qx 'AMP_CONTAINER=1' <<<"$out" || die "the entrypoint of ${IMAGE} did not hand over AMP_CONTAINER"
grep -qx 'TZ=Etc/UTC' <<<"$out" || die "the entrypoint of ${IMAGE} did not keep TZ"
