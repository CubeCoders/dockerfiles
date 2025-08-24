# Wine common dependencies image for AMP containers
# ghcr.io/cubecoders/amp:wine-common

FROM        debian:bookworm-slim AS depsfinder

ARG         TARGETARCH
ARG         BUILDS="stable devel staging 10-stable 9-stable"
#ARG         BUILDS="stable"
ARG         WINE_DIST="bookworm"

COPY        scripts/wine/find-deps.sh /usr/local/bin/find-deps.sh
COPY        scripts/wine/create-common-deps-list.sh /usr/local/bin/create-common-deps-list.sh
RUN         chmod +x /usr/local/bin/find-deps.sh /usr/local/bin/create-common-deps-list.sh

RUN         set -eux; \
            case "${TARGETARCH}" in \
                amd64) dpkg --add-architecture i386;; \
                arm64) dpkg --add-architecture armhf;; \
            esac; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                ca-certificates curl wget gnupg xz-utils dpkg-dev; \
            \
            export WINE_DIST="${WINE_DIST}"; \
            export WINE_FILES_DIR="/tmp/wine-files"; \
            mkdir -p "${WINE_FILES_DIR}"; \
            for build in ${BUILDS}; do \
                find-deps.sh $build >${WINE_FILES_DIR}/wine-deps-$build.txt; \
            done; \
            \
            rm -rf /var/lib/apt/lists/*; \
            \
            create-common-deps-list.sh ${WINE_FILES_DIR}/wine-deps-*.txt > "${WINE_FILES_DIR}/wine-common-deps-${TARGETARCH}.txt"

FROM        ghcr.io/cubecoders/amp:debian

LABEL       org.opencontainers.image.licenses=MIT

ARG         DEBIAN_FRONTEND=noninteractive
ARG         TARGETARCH

COPY        --from=depsfinder /tmp/wine-files /tmp/wine-files

# Install common packages
RUN         set -eux; \
            WINE_FILES_DIR="/tmp/wine-files"; \
            apt-get update; \
            apt-get install -y -o APT::Keep-Downloaded-Packages="false" --no-install-recommends cabextract winbind python3; \
            xargs -a "${WINE_FILES_DIR}/wine-common-deps-${TARGETARCH}.txt" apt-get install -y --install-recommends; \
            rm -rf ${WINE_FILES_DIR}; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*