# Wine common dependencies image for AMP containers
# ghcr.io/cubecoders/amp:wine-common

FROM        --platform=linux/amd64 debian:bookworm-slim AS depsfinder

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         WINE_DIST="bookworm"
#ARG         WINE_BRANCHES="stable devel staging 10-stable 9-stable"
ARG         WINE_BRANCHES="stable devel"

COPY        scripts/wine/find-deps.sh /usr/local/bin/find-deps.sh
COPY        scripts/wine/create-common-deps-list.sh /usr/local/bin/create-common-deps-list.sh
RUN         chmod +x /usr/local/bin/find-deps.sh /usr/local/bin/create-common-deps-list.sh

RUN         set -eux; \
            dpkg --add-architecture i386; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                ca-certificates curl wget gnupg xz-utils; \
            install -d -m 0755 /etc/apt/keyrings; \
            wget -qO- https://dl.winehq.org/wine-builds/winehq.key \
            | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -; \
            wget -NP /etc/apt/sources.list.d/ \
            "https://dl.winehq.org/wine-builds/debian/dists/${WINE_DIST}/winehq-${WINE_DIST}.sources"; \
            apt-get update; \
            \
            mkdir -p /tmp/wine-files; \
            for b in ${WINE_BRANCHES}; do \
                /usr/local/bin/find-deps.sh "${b}" >"/tmp/wine-files/${b}.amd64.txt"; \
            done; \
            /usr/local/bin/create-common-deps-list.sh /tmp/wine-files/*.amd64.txt \
                > /tmp/wine-files/wine-common-deps-amd64.txt

FROM        debian:bookworm-slim AS depsmapper

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH

COPY        --from=depsfinder /tmp/wine-files /tmp/wine-files

COPY        scripts/wine/map-x86-deps-to-arm.sh /usr/local/bin/map-x86-deps-to-arm.sh
RUN         chmod +x /usr/local/bin/map-x86-deps-to-arm.sh

# Generate common dependencies list for arm64
RUN         set -eux; \
            if [ "${TARGETARCH}" = "arm64" ]; then \
                /usr/local/bin/map-x86-deps-to-arm.sh \
                    < /tmp/wine-files/wine-common-deps-amd64.txt \
                    > /tmp/wine-files/wine-common-deps-arm64.txt; \
            fi

FROM        ghcr.io/cubecoders/amp:debian

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH

COPY        --from=depsmapper /tmp/wine-files /tmp/wine-files

# Install common dependencies
RUN         set -eux; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                cabextract winbind python3; \
            xargs -a "/tmp/wine-files/wine-common-deps-${TARGETARCH}.txt" \
                apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends; \
            rm -rf /tmp/wine-files; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*
