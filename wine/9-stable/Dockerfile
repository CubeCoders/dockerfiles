# Wine image for AMP containers based on Wine 9 stable
# ghcr.io/cubecoders/amp:wine-9-stable

FROM        --platform=linux/amd64 debian:bookworm-slim AS depsfinder

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         WINE_DIST="bookworm"
ARG         WINE_BRANCH="9-stable"

COPY        scripts/wine/find-deps.sh /usr/local/bin/find-deps.sh
RUN         chmod +x /usr/local/bin/find-deps.sh

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
            /usr/local/bin/find-deps.sh "${WINE_BRANCH}" >"/tmp/wine-files/${WINE_BRANCH}.amd64.txt"; \
            cp /tmp/wine-files/${WINE_BRANCH}.amd64.txt /tmp/wine-files/wine-deps-amd64.txt

FROM        debian:bookworm-slim AS depsmapper

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH

COPY        --from=depsfinder /tmp/wine-files /tmp/wine-files

COPY        scripts/wine/map-x86-deps-to-arm.sh /usr/local/bin/map-x86-deps-to-arm.sh
RUN         chmod +x /usr/local/bin/map-x86-deps-to-arm.sh

# Generate dependencies list for arm64
RUN         set -eux; \
            if [ "${TARGETARCH}" = "arm64" ]; then \
                /usr/local/bin/map-x86-deps-to-arm.sh \
                    < /tmp/wine-files/wine-deps-amd64.txt \
                    > /tmp/wine-files/wine-deps-arm64.txt; \
            fi

FROM        ghcr.io/cubecoders/amp:debian

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH
ARG         WINE_DIST="bookworm"
ARG         WINE_BRANCH="stable"
ARG         WINE_LINK="https://dl.winehq.org/wine-builds/debian/pool/main/w/wine/"
ARG         WINE_TARGET="9"

COPY        --from=depsfinder /tmp/wine-files /tmp/wine-files

# Install additional required packages and Wine 9 stable
RUN         set -eux; \
            WINE_BUILD="$( \
                curl -fsSL "${WINE_LINK}" \
                | grep -oE "wine-${WINE_BRANCH}-amd64_[0-9][0-9.]*~${WINE_DIST}(-[0-9]+)?_amd64\.deb" \
                | sed -E "s/^wine-${WINE_BRANCH}-amd64_([0-9.]+~${WINE_DIST}(-[0-9]+)?)_amd64\.deb$/\1/" \
                | grep -E "^${WINE_TARGET}(\.|$)" \
                | sort -V | tail -1 \
            )"; \
            \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends cabextract winbind python3; \
            \
            case "${TARGETARCH}" in \
            \
                amd64) \
                    install -d -m 0755 /etc/apt/keyrings; \
                    wget -qO- https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -; \
                    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/${WINE_DIST}/winehq-${WINE_DIST}.sources; \
                    \
                    apt-get update; \
                    apt-get install -o APT::Keep-Downloaded-Packages="false" -y --install-recommends \
                        apt-get install -o APT::Keep-Downloaded-Packages="false" -y --install-recommends \
                        wine-${WINE_BRANCH}-i386=${WINE_BUILD} \
                        wine-${WINE_BRANCH}-amd64=${WINE_BUILD} \
                        wine-${WINE_BRANCH}=${WINE_BUILD} \
                        winehq-${WINE_BRANCH}=${WINE_BUILD}; \
                    ;; \
                \
                arm64) \
                    apt-get update; \
                    xargs -ra /tmp/wine-files/wine-deps-arm64.txt \
                        apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends; \
                    \
                    apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                        dpkg-dev; \
                    \
                    for n in \
                        "wine-${WINE_BRANCH}-amd64_${WINE_BUILD}_amd64.deb" \
                        "wine-${WINE_BRANCH}_${WINE_BUILD}_amd64.deb" \
                        "winehq-${WINE_BRANCH}_${WINE_BUILD}_amd64.deb" \
                        "wine-${WINE_BRANCH}-i386_${WINE_BUILD}_i386.deb" ; do \
                            wget -q -P /tmp/wine-files "${WINE_LINK}${n}"; \
                        done; \
                    for d in /tmp/wine-files/*.deb; do dpkg-deb -x "$d" /wine-installer; done; \
                    mv /wine-installer/opt/wine* /opt/wine-${WINE_BRANCH}; \
                    rm -rf /wine-installer; \
                    \
                    if [ -f /opt/wine-${WINE_BRANCH}/bin/wine64 ]; then \
                        ln -sf /opt/wine-${WINE_BRANCH}/bin/wine64 /usr/bin/wine; \
                        ln -sf /opt/wine-${WINE_BRANCH}/bin/wine /usr/bin/wine32; \
                    else \
                        ln -sf /opt/wine-${WINE_BRANCH}/bin/wine /usr/bin/wine; \
                    fi; \
                    ln -sf /opt/wine-${WINE_BRANCH}/bin/wineboot /usr/bin/wineboot; \
                    ln -sf /opt/wine-${WINE_BRANCH}/bin/winecfg /usr/bin/winecfg; \
                    ln -sf /opt/wine-${WINE_BRANCH}/bin/wineserver /usr/bin/wineserver; \
                    chmod +x /usr/bin/wine /usr/bin/wineboot /usr/bin/winecfg /usr/bin/wineserver; \
                    if [ -f /usr/bin/wine32 ]; then chmod +x /usr/bin/wine32; fi; \
                    ;; \
            esac; \
            \
            rm -rf /tmp/wine-files; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*
