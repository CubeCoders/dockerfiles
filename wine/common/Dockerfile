# Wine common dependencies image for AMP containers
# cubecoders/ampbase:wine-common

ARG         DEPSFINDER_PLATFORM=linux/amd64
FROM        --platform=${DEPSFINDER_PLATFORM} debian:trixie-slim AS depsfinder

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         WINE_DIST="trixie"
ARG         WINE_BRANCHES="stable devel staging 11-stable 10-stable 9-stable"

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
            for b in ${WINE_BRANCHES}; do \
                /usr/local/bin/find-deps.sh "${b}" >"/tmp/wine-${b}-deps-amd64.txt"; \
            done; \
            mkdir -p /tmp/wine-files; \
            /usr/local/bin/create-common-deps-list.sh /tmp/wine-*-deps-amd64.txt \
                > /tmp/wine-files/wine-common-deps-amd64.txt; \
            mv /tmp/wine-*-deps-amd64.txt /tmp/wine-files/

FROM        debian:trixie-slim AS depsmapper

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH

COPY        --from=depsfinder /tmp/wine-files /tmp/wine-files

COPY        scripts/wine/map-x86-deps-to-arm.sh /usr/local/bin/map-x86-deps-to-arm.sh
RUN         chmod +x /usr/local/bin/map-x86-deps-to-arm.sh

# Generate common dependencies list for arm64
RUN         set -eux; \
            if [ "${TARGETARCH}" = "arm64" ]; then \
                dpkg --add-architecture armhf; \
                apt-get update; \
                apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                    xz-utils; \
                for f in /tmp/wine-files/*-deps-amd64.txt; do \
                    base="$(basename "$f" -deps-amd64.txt)"; \
                    /usr/local/bin/map-x86-deps-to-arm.sh "$f" >"/tmp/wine-files/${base}-deps-arm64.txt"; \
                done; \
            fi

FROM        cubecoders/ampbase:debian

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
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*
