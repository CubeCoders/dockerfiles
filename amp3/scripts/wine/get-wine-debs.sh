#!/bin/sh

set -eu

ARCH="${1:?usage: $0 amd64|i386|version}"
BRANCH="${WINE_BRANCH:-stable}"
DIST="${WINE_DIST:-trixie}"
case "${BRANCH}" in staging) SRC="wine-staging";; *) SRC="wine";; esac
LINK="https://dl.winehq.org/wine-builds/debian/pool/main/w/${SRC}/"
export DEBIAN_FRONTEND=noninteractive

resolve_version() {
  curl -fsSL "${LINK}" \
    | grep -oE "wine-${BRANCH}(-amd64)?_[0-9][0-9.]*(~rc[0-9]+)?~${DIST}(-[0-9]+)?_amd64\.deb" \
    | sed -E "s/^wine-${BRANCH}(-amd64)?_([0-9][0-9.]*(~rc[0-9]+)?~${DIST}(-[0-9]+)?)_amd64\.deb$/\2/" \
    | grep -E "^${WINE_TARGET:-[0-9]+}(\.|~|$)" \
    | sort -V | tail -1
}

require_version() {
  [ -n "$1" ] || { echo "No ${WINE_TARGET:+${WINE_TARGET}-}${BRANCH} build for ${DIST} at ${LINK}" >&2; exit 2; }
}

if [ "${ARCH}" = "version" ]; then
  v="$(resolve_version)"
  require_version "${v}"
  echo "${v}"
  exit 0
fi

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg

WINE_BUILD="${WINE_BUILD:-$(resolve_version)}"
require_version "${WINE_BUILD}"
echo "Wine ${BRANCH} ${WINE_BUILD} for ${ARCH}"

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key
printf 'Types: deb deb-src\nURIs: https://dl.winehq.org/wine-builds/debian\nSuites: %s\nComponents: main\nArchitectures: amd64 i386\nSigned-By: /etc/apt/keyrings/winehq-archive.key\n' \
  "${DIST}" > /etc/apt/sources.list.d/winehq.sources
mkdir -p /out

if dpkg --compare-versions "${WINE_BUILD}" lt 10.15; then
  # No NTSYNC code before 10.15: WineHQ's binaries, all four fetched by the amd64 stage.
  [ "${ARCH}" = "amd64" ] || exit 0
  dpkg --add-architecture i386
  apt-get update
  cd /out && apt-get download -o APT::Sandbox::User=root \
    "wine-${BRANCH}-amd64=${WINE_BUILD}" "wine-${BRANCH}=${WINE_BUILD}" "winehq-${BRANCH}=${WINE_BUILD}" \
    "wine-${BRANCH}-i386:i386=${WINE_BUILD}"
  exit 0
fi

# The release's own linux-libc-dev predates linux/ntsync.h; backports carries a kernel that has it.
printf 'Types: deb\nURIs: http://deb.debian.org/debian\nSuites: %s-backports\nComponents: main\nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg\n' \
  "${DIST}" > /etc/apt/sources.list.d/backports.sources
# Build dependencies are purged afterwards, so the cached stage holds little more than /out.
dpkg-query -W -f='${Package}\n' | sort > /tmp/pkgs-before
apt-get update
# The toolchain WineHQ builds with ("GCC: (GNU) 14-win32" in its PE modules); only the kernel headers are newer.
case "${ARCH}" in amd64) MINGW="x86-64";; *) MINGW="i686";; esac
# WineHQ's staging build also links FFmpeg and pcsclite (winedmo, winscard); its stable build does not.
case "${SRC}" in wine-staging) EXTRA="libavformat-dev libpcsclite-dev";; *) EXTRA="";; esac
apt-get install -y --no-install-recommends -t "${DIST}-backports" linux-libc-dev
# Missing from WineHQ's Build-Depends (its build root provides them); without them configure
# drops winewayland, wineusb, opencl and the C++ PE modules (icu, dmsynth) without failing.
# shellcheck disable=SC2086
apt-get install -y --no-install-recommends build-essential dpkg-dev fakeroot debhelper \
  "gcc-mingw-w64-${MINGW}-win32" "g++-mingw-w64-${MINGW}-win32" \
  libusb-1.0-0-dev ocl-icd-opencl-dev libxkbregistry-dev ${EXTRA}

mkdir -p /build && cd /build
apt-get source -o APT::Sandbox::User=root "${SRC}=${WINE_BUILD}"
cd "$(find . -mindepth 1 -maxdepth 1 -type d | head -1)"
apt-get build-dep -y --no-install-recommends ./
dpkg-buildpackage -b -uc -us -j"$(nproc)"
grep -q '^#define HAVE_LINUX_NTSYNC_H 1' include/config.h || { echo "NTSYNC not detected by configure" >&2; exit 1; }

case "${ARCH}" in
  amd64) cp ../"wine-${BRANCH}_"*.deb ../"wine-${BRANCH}-amd64_"*.deb ../"winehq-${BRANCH}_"*.deb /out/;;
  *) cp ../"wine-${BRANCH}-i386_"*.deb /out/;;
esac
cd / && rm -rf /build
dpkg-query -W -f='${Package}\n' | sort > /tmp/pkgs-after
# The build dependencies pull in systemd, which is essential; this stage is discarded, so it may go.
comm -13 /tmp/pkgs-before /tmp/pkgs-after | xargs -r apt-get purge -y --allow-remove-essential
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/pkgs-before /tmp/pkgs-after
