#!/bin/sh
# Detect runtime Debian packages for /usr/local Python like python:3.x-slim

set -eu

# Ensure required tools exist (quietly install if needed)
if ! command -v ldd >/dev/null 2>&1 || ! command -v find >/dev/null 2>&1 || ! command -v dpkg-query >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update 1>&2
  apt-get install -y --no-install-recommends findutils libc-bin dpkg 1>&2
fi

# Collect targets under /usr/local: executables + .so files; skip Tkinter
targets="$(
  find /usr/local -type f \( -perm -111 -o -name '*.so' -o -name '*.so.*' \) \
       ! -name '*tkinter*' -print 2>/dev/null || true
)"

# If nothing to scan, still print the three base runtime packages and exit
if [ -z "${targets}" ]; then
  printf '%s\n' ca-certificates netbase tzdata
  exit 0
fi

# Resolve full transitive shared libs via ldd, drop /usr/local and linux-vdso
so_paths="$(
  printf '%s\n' "$targets" \
  | xargs -r ldd 2>/dev/null \
  | awk '
      # Typical: "libX.so => /path/libX.so (0x...)"
      /=>/ && $3 ~ /^\// { print $3; next }
      # Also: "   /path/libY.so (0x...)" (no "=>")
      /^[[:space:]]*\// { print $1 }
    ' \
  | grep -v '^/usr/local/' \
  | grep -v 'linux-vdso' \
  | sort -u
)"

# Map each real path to a package (keep :arch suffix), dedupe
pkgs="$(
  printf '%s\n' "$so_paths" \
  | sed -E 's#^/(usr/)?##' \
  | sed 's#^#*#' \
  | xargs -r dpkg-query --search 2>/dev/null \
  | awk 'sub(":$", "", $1) { print $1 }' \
  | sort -u
)"

# Output packages + the non-ELF runtime packages the scan can’t “see”
printf '%s\n' "$pkgs"
printf '%s\n' ca-certificates netbase tzdata
