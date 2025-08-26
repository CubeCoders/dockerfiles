#!/bin/sh

set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <file1> [file2 ...]" >&2
  exit 2
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT INT TERM

norm() {
  # $1 -> normalized unique list on stdout
  sed 's/\r$//' "$1" \
  | sed -e 's/^[[:space:]]\+//' -e 's/[[:space:]]\+$//' \
  | awk 'NF' \
  | sort -u
}

# Normalize each input
i=0
for f in "$@"; do
  i=$((i+1))
  norm "$f" >"${TMPDIR}/f${i}.norm"
done

# Intersect all non-empty normalized files
# If any file is empty, intersection is empty.
nonempty=""
for g in "${TMPDIR}"/f*.norm; do
  [ -s "$g" ] || { : > "${TMPDIR}/common"; echo -n ""; cat "${TMPDIR}/common"; exit 0; }
  nonempty="${nonempty} ${g}"
done

# Seed with the first, then narrow with grep -Fxf
set -- ${nonempty}
cp "$1" "${TMPDIR}/common"
shift
while [ "$#" -gt 0 ]; do
  # grep -Fxf returns 1 if no matches; we still want an empty file
  grep -Fxf "$1" "${TMPDIR}/common" > "${TMPDIR}/next" || true
  mv "${TMPDIR}/next" "${TMPDIR}/common"
  shift
done

cat "${TMPDIR}/common"
