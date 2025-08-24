#!/bin/sh

set -eux

TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT INT TERM

# Normalize: strip CR, trim, drop blanks, unique
norm() {
    # shellcheck disable=SC2002
    cat "$1" \
    | sed 's/\r$//' \
    | sed -e 's/^[[:space:]]\+//' -e 's/[[:space:]]\+$//' \
    | awk 'NF' \
    | sort -u
}

i=0
for f in "$@"; do
    i=$((i+1))
    norm "${f}" >"${TMPDIR}/f${i}.norm"
done

# Intersect all normalized files (empty if any input empty)
intersect() {
    set -- "$@"
    nonempty=
    for g in "$@"; do
        [ -s "${g}" ] && nonempty="${nonempty} ${g}"
    done
    [ -n "${nonempty}" ] || { :; return 0; }

    # shellcheck disable=SC2086
    set -- ${nonempty}
    cp "$1" "${TMPDIR}/common"
    shift
    while [ "$#" -gt 0 ]; do
        grep -Fxf "$1" "${TMPDIR}/common" >"${TMPDIR}/next" || true
        mv "${TMPDIR}/next" "${TMPDIR}/common"
        shift
    done
    cat "${TMPDIR}/common"
}

# Build the list of normalized files
FILES=$(seq 1 "$i" | sed "s#^#${TMPDIR}/f#g; s/\$/\.norm/")

# shellcheck disable=SC2086
COMMON="$(intersect ${FILES} || true)"

# Print in the order of the first file’s normalized list
if [ -n "${COMMON}" ]; then
    printf '%s\n' "${COMMON}" >"${TMPDIR}/common.set"
    awk 'NR==FNR { keep[$0]=1; next } keep[$0]' "${TMPDIR}/common.set" "${TMPDIR}/f1.norm"
fi
