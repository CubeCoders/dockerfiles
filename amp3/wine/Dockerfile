# syntax=docker/dockerfile:1

# AMPBASE names the wine-common image here, not a distro base.
ARG         AMPBASE="cubecoders/amp3base:wine-common"
ARG         WINE_DIST="trixie"

# WineHQ's packages for each build arch; 10.15 and later are rebuilt from source with NTSYNC (get-wine-debs.sh).
FROM        --platform=linux/amd64 debian:${WINE_DIST} AS debs-amd64
ARG         WINE_DIST
ARG         WINE_BRANCH="stable"
ARG         WINE_TARGET=""
ARG         WINE_BUILD=""
COPY        scripts/wine/get-wine-debs.sh /usr/local/bin/get-wine-debs.sh
RUN         sh /usr/local/bin/get-wine-debs.sh amd64

# The base is resolved here, before the i386 stage: once buildah has built a stage for another
# platform it pulls every later FROM, and a local build's base lives only in local storage.
FROM        ${AMPBASE} AS wine-base

FROM        --platform=linux/386 debian:${WINE_DIST} AS debs-i386
ARG         WINE_DIST
ARG         WINE_BRANCH="stable"
ARG         WINE_TARGET=""
ARG         WINE_BUILD=""
COPY        scripts/wine/get-wine-debs.sh /usr/local/bin/get-wine-debs.sh
RUN         sh /usr/local/bin/get-wine-debs.sh i386

FROM        wine-base

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses="MIT"
LABEL       org.opencontainers.image.title="AMPBase v3 (Wine)"
LABEL       org.opencontainers.image.description="AMPBase v3 plus a WineHQ build of Wine. Contains no AMP code."

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH
ARG         WINE_BRANCH="stable"
ARG         WINE_TARGET=""

# The packages are bind-mounted from the builder stages, so they never land in a layer.
RUN         --mount=type=bind,from=debs-amd64,source=/out,target=/tmp/wine-debs/amd64 \
            --mount=type=bind,from=debs-i386,source=/out,target=/tmp/wine-debs/i386 \
            set -eux; \
            ls /tmp/wine-debs/*; \
            case "${TARGETARCH}" in \
            \
                amd64) \
                    apt-get update; \
                    apt-get install -o APT::Keep-Downloaded-Packages="false" -y --install-recommends /tmp/wine-debs/*/*.deb; \
                    ;; \
                \
                arm64) \
                    apt-get update; \
                    xargs -ra "/tmp/wine-files/wine-${WINE_TARGET:+${WINE_TARGET}-}${WINE_BRANCH}-deps-arm64.txt" \
                        apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends; \
                    \
                    # The x86 builds, unpacked for box86/box64.
                    for d in /tmp/wine-debs/*/*.deb; do dpkg-deb -x "$d" /wine-installer; done; \
                    mv /wine-installer/opt/wine* /opt/wine-${WINE_BRANCH}; \
                    rm -rf /wine-installer; \
                    \
                    for file in /opt/wine-"${WINE_BRANCH}"/bin/*; do \
                        if [ -x "${file}" ]; then ln -sf "${file}" /usr/bin/"$(basename "${file}")"; fi; \
                    done; \
                    ;; \
            esac; \
            \
            rm -rf /tmp/wine-files; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*
