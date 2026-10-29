#!/bin/bash
#
# Usage: build-images.sh [--push] [--runtime docker|podman] [--repo NAME]
#                        [--platforms LIST] [--file PATH] [--dry-run] [--no-smoke]
#                        [tag ...]
#
#   --push       multi-arch via docker buildx, pushed to the registry
#   --runtime    docker (default) or podman; local builds are host-arch only
#   --repo       repository to tag into (default: the manifest's)
#   --platforms  comma-separated subset of each image's platforms
#   --file       manifest to read (default: images.json beside this script)
#   --dry-run    validate the manifest and print the build commands
#   --no-smoke   skip the smoke test that runs inside each image once it is built
#
# Requires jq, and curl for the Wine images. images.json is the matrix; file
# order is build order.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${HERE}/images.json"
REPO=""
RUNTIME="docker"
PUSH=0
DRY=0
SMOKE=1
PLATFORM_FILTER=""
ONLY=()

die() { echo "build-images: $*" >&2; exit 1; }

while (($#)); do
  case "$1" in
    --push)      PUSH=1 ;;
    --dry-run)   DRY=1 ;;
    --no-smoke)  SMOKE=0 ;;
    --runtime)   RUNTIME="${2:?--runtime needs a value}"; shift ;;
    --repo)      REPO="${2:?--repo needs a value}"; shift ;;
    --platforms) PLATFORM_FILTER="${2:?--platforms needs a value}"; shift ;;
    --file)      MANIFEST="${2:?--file needs a value}"; shift ;;
    -h|--help)   sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)          die "unknown option: $1" ;;
    *)           ONLY+=("$1") ;;
  esac
  shift
done

command -v jq >/dev/null 2>&1 || die "jq is required (apt install jq / dnf install jq)."
[[ -f "$MANIFEST" ]] || die "no manifest at $MANIFEST"
MANIFEST="$(cd "$(dirname "$MANIFEST")" && pwd)/$(basename "$MANIFEST")"

# The build context is the manifest's directory.
cd "$(dirname "$MANIFEST")"

jq -e . "$MANIFEST" >/dev/null 2>&1 || die "$MANIFEST is not valid JSON."

schema="$(jq -r '.schemaVersion' "$MANIFEST")"
[[ "$schema" == "1" ]] || die "schemaVersion '$schema' is not one this script understands (1)."

[[ -n "$REPO" ]] || REPO="$(jq -r '.repository' "$MANIFEST")"

# Every name, canonical or alias, has exactly one meaning.
dupes="$(jq -r '[.images[] | .tag, (.aliases // [])[]] | group_by(.) | map(select(length > 1) | .[0]) | .[]' "$MANIFEST")"
[[ -z "$dupes" ]] || die "a name is used more than once as a tag or alias: $(echo "$dupes" | tr '\n' ' ')"

# "from" must name an image that appears EARLIER in the file.
misordered="$(jq -r '
  reduce .images[] as $i ({seen: [], bad: []};
    (if ($i.from // null) != null
        and (($i.from == $i.tag) or (([.seen[] | select(. == $i.from)] | length) == 0))
     then .bad += ["\($i.tag) (from \($i.from))"] else . end)
    | .seen += [$i.tag])
  | .bad[]' "$MANIFEST")"
[[ -z "$misordered" ]] || die "every \"from\" must name an image earlier in the file (file order is build order): $(echo "$misordered" | tr '\n' ' ')"

# Retired tags map to live images; no retired or refused name is also a live one.
badretired="$(jq -r '[.images[].tag] as $tags | (.retired // {}) | to_entries[] | select(.value as $v | any($tags[]; . == $v) | not) | "\(.key) -> \(.value)"' "$MANIFEST")"
[[ -z "$badretired" ]] || die "every \"retired\" entry must map to an image in the file: $(echo "$badretired" | tr '\n' ' ')"

collisions="$(jq -r '[.images[] | .tag, (.aliases // [])[]] as $names | (((.retired // {}) | keys) + (.refused // [])) | .[] | select(. as $n | any($names[]; . == $n))' "$MANIFEST")"
[[ -z "$collisions" ]] || die "a retired or refused name is also a current tag or alias: $(echo "$collisions" | tr '\n' ' ')"

while IFS= read -r df; do
  [[ -f "$df" ]] || die "the manifest names a Dockerfile that does not exist: $df"
done < <(jq -r '.images[].dockerfile' "$MANIFEST")

if ((${#ONLY[@]})); then
  known="$(jq -r '.images[].tag' "$MANIFEST")"
  for t in "${ONLY[@]}"; do
    grep -qxF -- "$t" <<<"$known" || die "'$t' is not a canonical tag in the manifest (name canonical tags, not aliases)."
  done
fi

wanted() {
  ((${#ONLY[@]} == 0)) && return 0
  local t
  for t in "${ONLY[@]}"; do [[ "$t" == "$1" ]] && return 0; done
  return 1
}

run() {
  if ((DRY)); then printf '  '; printf '%q ' "$@"; printf '\n'; else "$@"; fi
}

case "$(uname -m)" in
  x86_64)        HOST_PLATFORM="linux/amd64" ;;
  aarch64|arm64) HOST_PLATFORM="linux/arm64" ;;
  *)             HOST_PLATFORM="" ;;
esac

# The value of build arg $1 in the image's "args", empty when it has none.
arg_value() {
  local kv
  for kv in "${kvs[@]}"; do
    if [[ "${kv%%=*}" == "$1" ]]; then echo "${kv#*=}"; return; fi
  done
}

# Resolved here rather than inside the build, so a cached build follows WineHQ's releases.
resolve_wine_build() {
  WINE_BRANCH="$(arg_value WINE_BRANCH)" WINE_TARGET="$(arg_value WINE_TARGET)" \
    WINE_DIST="$(arg_value WINE_DIST)" sh scripts/wine/get-wine-debs.sh version </dev/null
}

# The checks live in scripts/smoke.sh, which the GitHub Actions build runs as well.
smoke() {
  local runtime="$1" image="$2" dockerfile="$3" wine_build="$4" wine_target="$5"
  echo "--- smoke: ${image}"
  if ((DRY)); then
    echo "  ${runtime} run --rm --entrypoint bash ${image} -c <checks for ${dockerfile}>"
    echo "  ${runtime} run --rm -e AMP_AGENT_BIN=/usr/bin/env -e TZ=Etc/UTC ${image}"
    return
  fi
  SMOKE_RUNTIME="$runtime" bash "${HERE}/scripts/smoke.sh" "$image" "$dockerfile" "$wine_build" "$wine_target" \
    || die "smoke test failed for ${image}"
}

BUILT=()
SKIPPED=()

# One record per image; US/RS separators keep empty fields and spaces in arg values.
FS=$'\x1f'
RS=$'\x1e'

while IFS="$FS" read -r tag aliases dockerfile from platforms args; do
  wanted "$tag" || continue

  if [[ -n "$PLATFORM_FILTER" ]]; then
    kept=()
    IFS=',' read -r -a want <<<"$PLATFORM_FILTER"
    IFS=',' read -r -a have <<<"$platforms"
    for p in "${have[@]}"; do
      for w in "${want[@]}"; do [[ "$p" == "$w" ]] && kept+=("$p"); done
    done
    if ((${#kept[@]} == 0)); then
      echo "--- ${REPO}:${tag}: none of its platforms (${platforms}) are in --platforms ${PLATFORM_FILTER}; skipped"
      SKIPPED+=("$tag")
      continue
    fi
    platforms="$(IFS=','; echo "${kept[*]}")"
  fi

  cmd=(-f "$dockerfile" -t "${REPO}:${tag}")
  for a in $aliases; do cmd+=(-t "${REPO}:${a}"); done
  if [[ -n "$from" ]]; then
    base="${REPO}:${from}"
    # Rootless Podman stores a local build under localhost/. A Dockerfile that pins a platform on an
    # earlier stage makes buildah resolve every FROM as a pull, and a short name then needs a search
    # registry, so a local build names the base the way Podman stored it.
    [[ "$RUNTIME" == podman && $PUSH -eq 0 ]] && base="localhost/${base}"
    cmd+=(--build-arg "AMPBASE=${base}")
  fi
  kvs=()
  if [[ -n "$args" ]]; then
    IFS="$RS" read -r -a kvs <<<"$args"
    for kv in "${kvs[@]}"; do cmd+=(--build-arg "$kv"); done
  fi

  echo
  echo "=== ${REPO}:${tag}${aliases:+ (also: ${aliases})}  <-  ${dockerfile}${from:+  FROM ${REPO}:${from}}"

  wine_build=""
  if [[ "$dockerfile" == "wine/Dockerfile" ]]; then
    if ((DRY)); then
      wine_build="<resolved>"
      echo "  WINE_BRANCH=$(arg_value WINE_BRANCH) WINE_TARGET=$(arg_value WINE_TARGET) sh scripts/wine/get-wine-debs.sh version"
    else
      command -v curl >/dev/null 2>&1 || die "curl is required to resolve the Wine build for ${tag}."
      wine_build="$(resolve_wine_build)" || die "could not resolve the Wine build for ${tag}."
      echo "--- ${tag}: Wine ${wine_build}"
    fi
    cmd+=(--build-arg "WINE_BUILD=${wine_build}")
  fi

  if ((PUSH)); then
    # Built for this machine first and smoked, so a broken image is never pushed.
    if ((SMOKE)) && [[ ",${platforms}," == *",${HOST_PLATFORM},"* ]]; then
      run docker buildx build --platform "$HOST_PLATFORM" --pull --load "${cmd[@]}" .
      smoke docker "${REPO}:${tag}" "$dockerfile" "$wine_build" "$(arg_value WINE_TARGET)"
    elif ((SMOKE)); then
      echo "--- smoke: ${REPO}:${tag} is not built for ${HOST_PLATFORM:-this machine}; not smoked"
    fi
    run docker buildx build --platform "$platforms" --pull --push "${cmd[@]}" .
  else
    # No --pull: a derived image builds FROM the base this run just built locally.
    run "$RUNTIME" build "${cmd[@]}" .
    if ((SMOKE)); then smoke "$RUNTIME" "${REPO}:${tag}" "$dockerfile" "$wine_build" "$(arg_value WINE_TARGET)"; fi
  fi
  BUILT+=("$tag")
done < <(jq -r --arg fs "$FS" --arg rs "$RS" '
  .images[]
  | [ .tag,
      ((.aliases // []) | join(" ")),
      .dockerfile,
      (.from // ""),
      (.platforms | join(",")),
      ((.args // {}) | to_entries | map("\(.key)=\(.value)") | join($rs)) ]
  | join($fs)' "$MANIFEST")

echo
if ((${#BUILT[@]} == 0)); then
  if ((${#ONLY[@]})); then die "nothing built: no tag matched (${ONLY[*]})."; fi
  die "nothing built: every image was skipped by --platforms ${PLATFORM_FILTER}."
fi
if ((DRY)); then
  echo "Would build ${#BUILT[@]} image(s): ${BUILT[*]}"
else
  echo "Built ${#BUILT[@]} image(s): ${BUILT[*]}"
fi
if ((${#SKIPPED[@]})); then
  echo "Skipped ${#SKIPPED[@]} (platform filter): ${SKIPPED[*]}"
fi
