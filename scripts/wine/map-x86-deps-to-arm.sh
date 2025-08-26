#!/bin/sh

set -eu

NATIVE="${NATIVE:-arm64}"
COMPAT="${COMPAT:-armhf}"

# Make sure indexes for both arches exist for availability checks
dpkg --add-architecture "${COMPAT}" >/dev/null 2>&1 || true
apt-get -q -o Acquire::Languages=none update >/dev/null

# Helper dedupe
seen="$(mktemp)"; trap 'rm -f "$seen"' INT TERM EXIT
emit() {
  s=$1
  if ! grep -Fxq "$s" "${seen}" 2>/dev/null; then
    printf '%s\n' "${s}"
    printf '%s\n' "${s}" >>"${seen}"
  fi
}

has_candidate() {
  # $1 = token ("pkg" or "pkg:arch"); returns 0 if APT has a candidate
  cand=$(
    apt-cache policy "$1" 2>/dev/null \
      | sed -n 's/^[[:space:]]\{1,\}Candidate: //p' | head -1
  )
  [ -n "${cand:-}" ] && [ "${cand}" != "(none)" ]
}

# Read each line as a token "pkg[:arch]"
while IFS= read -r tok; do
  # trim whitespace and CR
  tok=${tok%$'\r'}
  tok=$(printf '%s' "${tok}" | sed 's/^[[:space:]]\+//; s/[[:space:]]\+$//')
  [ -z "${tok}" ] && continue
  case "${tok}" in \#*) continue ;; esac

  pkg=${tok%%:*}
  if [ "${pkg}" = "${tok}" ]; then
    suf=""
  else
    suf=${tok#*:}
  fi

  # no suffix/amd64 => arm64 ; i386 => armhf ; other arches => skip
  case "${suf}" in
    ""|"amd64") tgt="${NATIVE}" ;;
    "i386")     tgt="${COMPAT}" ;;
    *)          continue      ;;
  esac

  if has_candidate "${pkg}:${tgt}"; then
    emit "${pkg}:${tgt}"
  elif has_candidate "${pkg}"; then          # covers Architecture: all
    emit "${pkg}"
  fi
done
