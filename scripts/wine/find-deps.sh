#!/bin/sh

set -eu

BUILD="${1:-stable}"
WINE_DIST="${WINE_DIST:-trixie}"

# Helper: print Inst package names (sans wine metas), sorted unique
_print_inst() {
  awk '
    $1=="Inst" {
      pkg=$2; sub(/\).*$/,"",pkg)   # trim trailing ")..."
      # Drop wine meta/self packages
      if (pkg ~ /^(wine(|32|64)|winehq|wine-(devel|staging|stable))(:|$)/) next
      gsub(/[[:space:]]+/,"",pkg)
      print pkg
    }
  ' | sort -u
}

STATUS=/tmp/dpkg.status.empty
: > "$STATUS"

case "${BUILD}" in
  stable|devel|staging)
    apt-get -s install -y -o Dir::State::status="$STATUS" -o APT::Install-Recommends=1 -o APT::Architectures=amd64 -o APT::Architectures=i386 \
      "winehq-${BUILD}" \
    | _print_inst
    ;;

  *-stable)
    WINE_BRANCH="stable"
    MAJOR="${BUILD%%-*}"

    WINE_LINK="${WINE_LINK:-https://dl.winehq.org/wine-builds/debian/pool/main/w/wine/}"
    WINE_BUILD="$(
      curl -fsSL "${WINE_LINK}" \
      | grep -oE "wine-${WINE_BRANCH}-amd64_[0-9][0-9.]*~${WINE_DIST}(-[0-9]+)?_amd64\.deb" \
      | sed -E "s/^wine-${WINE_BRANCH}-amd64_([0-9.]+~${WINE_DIST}(-[0-9]+)?)_amd64\.deb$/\1/" \
      | awk -F. -v m="${MAJOR}" '$1==m' \
      | sort -V | tail -1
    )"
    if [ -z "${WINE_BUILD}" ]; then
      echo "Failed to resolve WINE_BUILD for ${BUILD} (dist=${WINE_DIST})." >&2
      exit 2
    fi

    apt-get -s install -y -o Dir::State::status="$STATUS" -o APT::Install-Recommends=1 -o APT::Architectures=amd64 -o APT::Architectures=i386 \
      "wine-${WINE_BRANCH}-i386=${WINE_BUILD}" \
      "wine-${WINE_BRANCH}-amd64=${WINE_BUILD}" \
      "wine-${WINE_BRANCH}=${WINE_BUILD}" \
      "winehq-${WINE_BRANCH}=${WINE_BUILD}" \
    | _print_inst
    ;;

  *)
    echo "Unknown build: ${BUILD}" >&2
    exit 1
    ;;
esac
