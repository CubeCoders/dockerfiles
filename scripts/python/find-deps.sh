#!/bin/sh

set -eu

VER="$1"

export DEBIAN_FRONTEND=noninteractive
apt-get update 1>&2
apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends binutils dpkg findutils libc-bin 1>&2

# build scan list only from existing files
scan_paths=""
for p in /usr/local/bin/python3 \
         /usr/local/lib/libpython*.so* \
         /usr/local/lib/python*/lib-dynload/*.so; do
  [ -e "$p" ] && scan_paths="$scan_paths $p"
done

# DT_NEEDED sonames (no execution)
neededs=$(
  objdump -p $scan_paths 2>/dev/null | awk '/^  NEEDED /{print $2}' | sort -u
)

# Resolve SONAMEs to real files by scanning common lib dirs
so_files=$(
  for so in $neededs; do
    for d in \
      /lib/*-linux-gnu /usr/lib/*-linux-gnu \
      /lib /usr/lib; do
      f="$d/$so"
      [ -e "$f" ] && printf '%s\n' "$f"
    done
  done | sort -u
)

# Map files -> packages
printf '%s\n' $so_files | xargs -r dpkg -S | cut -d: -f1 | sort -u
