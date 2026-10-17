#!/bin/sh
# Put WineHQ's debs for one build arch (amd64|i386) in /out.
# Versions with NTSYNC code (>= 10.15) are rebuilt from WineHQ's signed source against newer kernel headers
# (WineHQ's trixie binaries lack it: trixie's linux-libc-dev predates linux/ntsync.h); older ones are WineHQ's binaries.

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

# CI resolves the version up front and passes WINE_BUILD, so the cached Wine build follows upstream releases
if [ "${ARCH}" = "version" ]; then v="$(resolve_version)"; test -n "${v}"; echo "${v}"; exit 0; fi

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg

WINE_BUILD="${WINE_BUILD:-$(resolve_version)}"
test -n "${WINE_BUILD}"
echo "Wine ${BRANCH} ${WINE_BUILD} for ${ARCH}"

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key
printf 'Types: deb deb-src\nURIs: https://dl.winehq.org/wine-builds/debian\nSuites: %s\nComponents: main\nArchitectures: amd64 i386\nSigned-By: /etc/apt/keyrings/winehq-archive.key\n' \
  "${DIST}" > /etc/apt/sources.list.d/winehq.sources
mkdir -p /out

if dpkg --compare-versions "${WINE_BUILD}" lt 10.15; then
  # No NTSYNC code: WineHQ's binaries, all fetched by the amd64 stage
  [ "${ARCH}" = "amd64" ] || exit 0
  dpkg --add-architecture i386
  apt-get update
  cd /out && apt-get download -o APT::Sandbox::User=root \
    "wine-${BRANCH}-amd64=${WINE_BUILD}" "wine-${BRANCH}=${WINE_BUILD}" "winehq-${BRANCH}=${WINE_BUILD}" \
    "wine-${BRANCH}-i386:i386=${WINE_BUILD}"
  exit 0
fi

printf 'Types: deb\nURIs: http://deb.debian.org/debian\nSuites: %s-backports\nComponents: main\nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg\n' \
  "${DIST}" > /etc/apt/sources.list.d/backports.sources
# Build deps are purged afterwards so the cached layer is just /out (GHA cache is 10GB per repo)
dpkg-query -W -f='${Package}\n' | sort > /tmp/pkgs-before
apt-get update
# Same toolchain WineHQ uses ("GCC: (GNU) 14-win32" in its PE modules), only the kernel headers are newer
case "${ARCH}" in amd64) MINGW="x86-64";; *) MINGW="i686";; esac
# WineHQ's staging build also links FFmpeg and pcsclite (winedmo, winscard); stable's doesn't
case "${SRC}" in wine-staging) EXTRA="libavformat-dev libpcsclite-dev";; *) EXTRA="";; esac
apt-get install -y --no-install-recommends -t "${DIST}-backports" linux-libc-dev
# Missing from WineHQ's Build-Depends (their OBS build root provides them); without them configure silently
# drops winewayland, wineusb, opencl and the C++ PE modules (icu, dmsynth)
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
# Build deps pull in systemd (essential), harmless to drop in this throwaway stage
comm -13 /tmp/pkgs-before /tmp/pkgs-after | xargs -r apt-get purge -y --allow-remove-essential
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/pkgs-before /tmp/pkgs-after
