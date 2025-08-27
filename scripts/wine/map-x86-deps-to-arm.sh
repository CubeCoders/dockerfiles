#!/bin/bash

set -eu

IN="${1:?usage: $0 combined.txt}"
NATIVE="arm64"
FROM_COMPAT="i386"
TO_COMPAT="armhf"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
MAP="$tmp/map" Q="$tmp/queries" HAVE="$tmp/have"

# Build query->output map:
# - native "pkg"       => query "pkg:arm64", output "pkg"
# - compat "pkg:i386"  => query "pkg:armhf", output "pkg:armhf"
awk -v from="$FROM_COMPAT" -v to="$TO_COMPAT" -v nat="$NATIVE" '
  BEGIN{FS=OFS="\t"}
  /^[[:space:]]*(#|$)/ { next }
  { gsub(/^[ \t]+|[ \t]+$/,"") }
  $0 ~ ":" from "$" {
    base=$0; sub(/:.*/,"",base);
    print base ":" to, base ":" to; next
  }
  $0 !~ /:/ {
    base=$0;
    print base ":" nat, base; next
  }
  # ignore any other arch-suffixed lines
' "$IN" | sort -u > "$MAP"

# Enable compat arch if needed (once)
if grep -q ":$TO_COMPAT" "$MAP" && ! dpkg --print-foreign-architectures | grep -qx "$TO_COMPAT"; then
  dpkg --add-architecture "$TO_COMPAT"
fi

apt-get -qq -o Acquire::Languages=none update >/dev/null

cut -f1 "$MAP" > "$Q"

# Batch policy; normalize native headers lacking ":arch" to ":$NATIVE"
xargs -a "$Q" -r apt-cache policy -- 2>/dev/null \
| awk -v nat="$NATIVE" '
  /^[^ ]+:$/ {                      # stanza header like "pkg:" or "pkg:armhf:"
    raw=$1; sub(/:$/,"",raw)        # strip trailing colon
    if (raw ~ /:[^:]+$/) p=raw      # already has :arch
    else p=raw ":" nat              # add native arch when missing
    next
  }
  /^  Candidate:/ && $2!="(none)" { print p }
' > "$HAVE"

# Map back to requested names and dedupe
awk -F"\t" 'NR==FNR {m[$1]=$2; next} ($1 in m){print m[$1]}' "$MAP" "$HAVE" | sort -u
