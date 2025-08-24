# Wine image for AMP containers based on Wine devel
# ghcr.io/cubecoders/amp:wine-devel

FROM        debian:bookworm-slim AS depsfinder

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH
ARG         WINE_LINK="https://dl.winehq.org/wine-builds/debian/pool/main/w/wine/"
ARG         WINE_BRANCH="devel"
ARG         WINE_DIST="bookworm"

COPY        scripts/wine/find-deps.sh /usr/local/bin/find-deps.sh
RUN         chmod +x /usr/local/bin/find-deps.sh

RUN         set -eux; \
            export WINE_FILES_DIR="/tmp/wine-files"; \
            mkdir -p "${WINE_FILES_DIR}"; \
            if [ "${TARGETARCH}" = "arm64" ]; then \
                apt-get update; \
                apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                    ca-certificates curl wget gnupg xz-utils dpkg-dev; \
                \
                export WINE_DIST="${WINE_DIST}"; \
                find-deps.sh "${WINE_BRANCH}" >${WINE_FILES_DIR}/wine-deps.txt; \
                \
                rm -rf /var/lib/apt/lists/*; \
            fi
            
FROM        ghcr.io/cubecoders/amp:wine-common

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH
ARG         WINE_LINK="https://dl.winehq.org/wine-builds/debian/pool/main/w/wine/"
ARG         WINE_BRANCH="devel"
ARG         WINE_DIST="bookworm"

COPY        --from=depsfinder /tmp/wine-files /tmp/wine-files

# Install required packages and Wine devel
RUN         set -eux; \
            WINE_FILES_DIR="/tmp/wine-files"; \
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
                        winehq-devel; \
                    ;; \
                \
                arm64) \
                    for deb in ${WINE_FILES_DIR}/*.deb; do dpkg-deb -x "$deb" /wine-installer; done; \
                    mv /wine-installer/opt/wine* /opt/wine-${WINE_DIST}; \
                    rm -rf /wine-installer; \
                    \
                    xargs -ra "${WINE_FILES_DIR}/wine-deps.txt" apt-get install -o APT::Keep-Downloaded-Packages="false" -y --install-recommends; \
                    \
                    if [ -f /opt/wine-${WINE_DIST}/bin/wine64 ]; then \
                        ln -sf /opt/wine-${WINE_DIST}/bin/wine64 /usr/bin/wine; \
                        ln -sf /opt/wine-${WINE_DIST}/bin/wine /usr/bin/wine32; \
                    else \
                        ln -sf /opt/wine-${WINE_DIST}/bin/wine /usr/bin/wine; \
                    fi; \
                    ln -sf /opt/wine-${WINE_DIST}/bin/wineboot /usr/bin/wineboot; \
                    ln -sf /opt/wine-${WINE_DIST}/bin/winecfg /usr/bin/winecfg; \
                    ln -sf /opt/wine-${WINE_DIST}/bin/wineserver /usr/bin/wineserver; \
                    chmod +x /usr/bin/wine /usr/bin/wineboot /usr/bin/winecfg /usr/bin/wineserver; \
                    if [ -f /usr/bin/wine32 ]; then chmod +x /usr/bin/wine32; fi; \
                    ;; \
            esac; \
            \
            rm -rf ${WINE_FILES_DIR}; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*