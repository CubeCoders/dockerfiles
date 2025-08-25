#!/bin/sh

set -eux

BUILD="${1:-stable}"
WINE_DIST="${WINE_DIST:-bookworm}"
WINE_FILES_DIR="${WINE_FILES_DIR:-/tmp/wine-files}"
WINE_LINK="https://dl.winehq.org/wine-builds/debian/pool/main/w/wine$( [ "${BUILD}" = staging ] && printf -- '-staging' || true)/"

case "${BUILD}" in
    stable|devel|staging)
        WINE_BRANCH="${BUILD}"
        MAJOR=""
        ;;
    *-stable)
        WINE_BRANCH="stable"
        MAJOR="${BUILD%%-*}"
        ;;
    *)
        echo "Unknown build: ${BUILD}" >&2
        exit 1
        ;;
esac

latest_version() {
    branch="$1"
    major="${2:-}"

    # List matching debs, extract version, optional major filter, pick latest
    curl -fsSL "${WINE_LINK}" \
    | grep -oE "wine-${branch}-amd64_[0-9][0-9.]*~${WINE_DIST}(-[0-9]+)?_amd64\.deb" \
    | sed -E "s/^wine-${branch}-amd64_([0-9.]+)~${WINE_DIST}(-[0-9]+)?_amd64\.deb$/\1/" \
    | { [ -n "${major}" ] && awk -F. -v m="${major}" '$1==m' || cat; } \
    | sort -V \
    | tail -1
}

WINE_VERSION="$(latest_version "${WINE_BRANCH}" "${MAJOR}")"

# Helper: select the actual file name (keeps the real -<rev>)
pick_file() {
    patt="$1"
    curl -fsSL "${WINE_LINK}" \
    | grep -oE "${patt}" \
    | sort -V \
    | tail -1
}

DEB_A1="$(pick_file "wine-${WINE_BRANCH}-amd64_${WINE_VERSION}~${WINE_DIST}(-[0-9]+)?_amd64\.deb")"
DEB_A2="$(pick_file "wine-${WINE_BRANCH}_${WINE_VERSION}~${WINE_DIST}(-[0-9]+)?_amd64\.deb")"
DEB_A3="$(pick_file "winehq-${WINE_BRANCH}_${WINE_VERSION}~${WINE_DIST}(-[0-9]+)?_amd64\.deb")"
DEB_B1="$(pick_file "wine-${WINE_BRANCH}-i386_${WINE_VERSION}~${WINE_DIST}(-[0-9]+)?_i386\.deb")"

mkdir -p "${WINE_FILES_DIR}"

wget -q -P "${WINE_FILES_DIR}" -- "${WINE_LINK}${DEB_A1}"
wget -q -P "${WINE_FILES_DIR}" -- "${WINE_LINK}${DEB_A2}"
wget -q -P "${WINE_FILES_DIR}" -- "${WINE_LINK}${DEB_A3}"
wget -q -P "${WINE_FILES_DIR}" -- "${WINE_LINK}${DEB_B1}"

: >/tmp/wine-reqs.amd64
: >/tmp/wine-reqs.i386

# Collect dependencies (64-bit)
for deb in "${WINE_FILES_DIR}"/"${DEB_A1}" "${WINE_FILES_DIR}"/"${DEB_A2}" "${WINE_FILES_DIR}"/"${DEB_A3}"; do
    {
        dpkg-deb -I "${deb}" \
        | awk -F': ' '/^( Depends| Recommends):/{print $2}' \
        | tr ',' '\n' \
        | sed -E 's/\(.*\)//; s/^[[:space:]]+|[[:space:]]+$//g' \
        | grep -E '.' \
        | grep -Ev '^(wine|winehq)[[:alnum:]-]*$'
    } >> /tmp/wine-reqs.amd64 || :
done

# Collect dependencies (32-bit)
{
    dpkg-deb -I "${WINE_FILES_DIR}"/"${DEB_B1}" \
    | awk -F': ' '/^( Depends| Recommends):/{print $2}' \
    | tr ',' '\n' \
    | sed -E 's/\(.*\)//; s/^[[:space:]]+|[[:space:]]+$//g' \
    | grep -E '.' \
    | grep -Ev '^(wine|winehq)[[:alnum:]-]*$'
} >> /tmp/wine-reqs.i386 || :

NATIVE="$(dpkg --print-architecture 2>/dev/null)"
case "${NATIVE}" in
    amd64) COMPAT="i386";;
    arm64) COMPAT="armhf";;
esac

dedup() {
    awk '!seen[$0]++ && NF'
}

# Build token set (explode alts, strip versions/quals)
TOKENS="$(mktemp)"
cat /tmp/wine-reqs.amd64 /tmp/wine-reqs.i386 \
| awk 'BEGIN{RS="|"}{gsub(/^[ \t]+|[ \t]+$/,""); if(length)print}' \
| sed -E 's/\(.*\)//; s/:any$//; s/:all$//; s/^[[:space:]]+|[[:space:]]+$//g' \
| awk -F: '{print $1}' | dedup >"${TOKENS}"

# Availability caches (store base names for both arches)
AVN="$(mktemp)"; : >"${AVN}"
AVC="$(mktemp)"; : >"${AVC}"

# Native availability
xargs -a "${TOKENS}" -r -I{} printf '%s:%s\n' '{}' "${NATIVE}" \
| xargs -r apt-cache policy -- 2>/dev/null \
| awk '
    /^[^ ]+:$/ {p=$1; sub(/:$/,"",p); next}
    /^  Candidate: / && $3!="(none)" {
        base=p; sub(/:.*/,"",base); print base
    }' | sort -u >"${AVN}"

# Compat availability
if [ -n "${COMPAT}" ]; then
    xargs -a "${TOKENS}" -r -I{} printf '%s:%s\n' '{}' "${COMPAT}" \
    | xargs -r apt-cache policy -- 2>/dev/null \
    | awk '
        /^[^ ]+:$/ {p=$1; sub(/:$/,"",p); next}
        /^  Candidate: / && $3!="(none)" {
        base=p; sub(/:.*/,"",base); print base
        }' | sort -u >"${AVC}"
fi

# Helper: pick first available alternative against given availability cache
pick_alt() { line=$1; avail=$2; suff=${3:-}; OLDIFS=${IFS}; IFS='|'
    for t in ${line}; do
        p=$(printf '%s' "${t}" | sed -E 's/\(.*\)//; s/:any$//; s/:all$//; s/^[[:space:]]+|[[:space:]]+$//g')
        [ -n "${p}" ] || continue
        if grep -Fxq "${p}" "${avail}"; then
        [ -n "${suff}" ] && { printf '%s:%s\n' "${p}" "${suff}"; IFS=${OLDIFS}; return 0; }
        printf '%s\n' "${p}"; IFS=${OLDIFS}; return 0
        fi
    done
    IFS=${OLDIFS}; return 1
}

# Helper: return 0 if pkg:arch is Multi-Arch: same, else 1
ma_same_pkg() { # $1=pkg  $2=arch
  apt-cache show "$1:$2" 2>/dev/null \
  | awk -v p="$1" -v a="$2" -F': ' '
      # parse stanza-by-stanza
      NF==0 { if (pk && ar==a && tolower(ma)=="same") {ok=1} pk=ar=ma=""; next }
      $1=="Package"      { pk=$2 }
      $1=="Architecture" { ar=$2 }
      $1=="Multi-Arch"   { ma=$2 }
      END { if (pk && ar==a && tolower(ma)=="same") ok=1; exit (ok?0:1) }
    '
}

# Native → print bare names (stable de-dupe)
NSET="$(mktemp)"; : >"${NSET}"
while IFS= read -r L; do
    sel="$(pick_alt "${L}" "${AVN}" || true)"; [ -n "${sel}" ] || continue
    if ! grep -Fxq "${sel}" "${NSET}"; then printf '%s\n' "${sel}"; printf '%s\n' "${sel}" >>"${NSET}"; fi
done < /tmp/wine-reqs.amd64

# Compat → pick vs compat cache; avoid native clash unless MA:same; print with :arch
if [ -n "${COMPAT}" ]; then
    while IFS= read -r L; do
        first="$(pick_alt "${L}" "${AVC}" "${COMPAT}" || true)"; [ -n "${first}" ] || continue
        base="${first%:*}"

        chosen=""
        if ! grep -Fxq "${base}" "${NSET}"; then
            chosen="${first}"
        else
            if ma_same_pkg "${base}" "${COMPAT}"; then
                chosen="${first}"
            else
                OLDIFS=${IFS}; IFS='|'
                for t in ${L}; do
                    p=$(printf '%s' "${t}" | sed -E 's/\(.*\)//; s/:any$//; s/:all$//; s/^[[:space:]]+|[[:space:]]+$//g')
                    [ -n "${p}" ] || continue
                    grep -Fxq "${p}" "${AVC}" || continue
                    if ! grep -Fxq "${p}" "${NSET_SORT}" || ma_same_pkg "${p}" "${COMPAT}"; then
                        chosen="${p}:${COMPAT}"; break
                    fi
                done
                IFS=${OLDIFS}
            fi
        fi

        [ -n "${chosen}" ] && printf '%s\n' "${chosen}"
    done < /tmp/wine-reqs.i386 | dedup
fi

# cleanup
rm -f "${TOKENS}" "${AVN}" "${AVC}" "${NSET}" 2>/dev/null || true
