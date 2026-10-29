# AMPBase v3 images (cubecoders/amp3base)

This directory holds the container images AMP3 runs its instances in, published to Docker Hub as `cubecoders/amp3base:<tag>`. They contain no AMP code. The AMP2 family (`cubecoders/ampbase`) is at the root of this repository.

These images are not designed to be run directly: AMP3 starts them.

## images.json

`images.json` is the build matrix and the catalogue AMP3 reads. Each entry names a canonical tag, its aliases, its Dockerfile, the tag of this family it builds FROM, its platforms and its build args. File order is build order: an image's `from` must appear earlier in the file. `images.schema.json` describes the file; `build-images.sh` checks what the schema cannot (one meaning per name, FROM order, Dockerfiles that exist).

`published/images.json` is the copy AMP3 fetches, through https://cdn-repo.c7rs.com/dockerfiles/amp3/published/images.json. CI writes it, and only once every tag and alias in `images.json` answers on Docker Hub for every platform it lists. Do not edit it by hand.

## CI

GitHub reads workflows only from the root of a repository, so the workflows and the action for this directory live there:

- `.github/workflows/amp3-images.yml` plans the build from `images.json`, builds each level of the FROM graph after the level it builds on, then publishes `published/images.json`.
- `.github/workflows/amp3-images-build.yml` builds one level, one job per image.
- `.github/actions/amp3-build-image/action.yml` builds an image for linux/amd64, runs `scripts/smoke.sh` against it, then builds and pushes every platform the image lists.

The workflow runs on a push to master that changes `amp3/` (except `amp3/published/`), weekly, and on demand with an optional list of canonical tags. In AMP3's own repository this directory is `deploy/docker`, with its `.github/` beside this file; moving it here merges that `.github/` into the repository root.

## Adding an image

1. Add an entry to `images.json`, after the image it builds FROM.
2. Add its Dockerfile. A derived image takes its base as `ARG AMPBASE="cubecoders/amp3base:<from>"` and `FROM ${AMPBASE}`.
3. Add its checks to `scripts/smoke.sh`, keyed by Dockerfile path.
4. Add a row for the tag to AMP3's catalogue tests (`SharedTests/ContainerImageCatalogTests.cs`) when it carries an AMP2 name.

A merge to master builds and pushes the new tag, then publishes it to AMP3.

## Building locally

`build-images.sh` builds the same matrix on one machine and runs the same smoke test. It needs jq, and curl for the Wine images.

```sh
./build-images.sh --dry-run                       # check images.json, print the build commands
./build-images.sh --runtime podman debian java-lts
./build-images.sh --push --repo registry.example/amp3base
```

Without `--push` it builds this machine's architecture only and keeps the result in the local image store. `./build-images.sh --help` lists every option.
