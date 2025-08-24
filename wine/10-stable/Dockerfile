# Wine image for AMP containers based on Wine 10 stable
# ghcr.io/cubecoders/amp:wine-10-stable

FROM        debian:bookworm-slim AS depsfinder

ARG         WINE_LINK="https://dl.winehq.org/wine-builds/debian/pool/main/w/wine/"
ARG         WINE_BRANCH="stable"
ARG         WINE_DIST="bookworm"
ARG         WINE_TARGET="10"

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
                find-deps.sh "${WINE_TARGET}-${WINE_BRANCH}" >${WINE_FILES_DIR}/wine-deps.txt; \
                \
                rm -rf /var/lib/apt/lists/*; \
            fi
            
FROM        ghcr.io/cubecoders/amp:wine-common

LABEL       org.opencontainers.image.licenses=MIT

ARG         DEBIAN_FRONTEND="noninteractive"
ARG         TARGETARCH

ARG         WINE_LINK="https://dl.winehq.org/wine-builds/debian/pool/main/w/wine/"
ARG         WINE_BRANCH="stable"
ARG         WINE_DIST="bookworm"
ARG         WINE_TARGET="10"

COPY        --from=depsfinder /tmp/wine-files /tmp/wine-files

# Install required packages and Wine 10 stable
RUN         set -eux; \
            WINE_FILES_DIR="/tmp/wine-files"; \
            WINE_BUILD="$( \
                curl -fsSL "${WINE_LINK}" \
                | grep -oE "wine-${WINE_BRANCH}-amd64_[0-9][0-9.]*~${WINE_DIST}(-[0-9]+)?_amd64\.deb" \
                | sed -E "s/^wine-${WINE_BRANCH}-amd64_([0-9.]+~${WINE_DIST}(-[0-9]+)?)_amd64\.deb$/\1/" \
                | grep -E "^${WINE_TARGET}(\.|$)" \
                | sort -V | tail -1 \
            )"; \
            WINE_VERSION="${WINE_VERSION%%~*}"; \
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
                        wine-${WINE_BRANCH}-i386=${WINE_BUILD} \
                        wine-${WINE_BRANCH}-amd64=${WINE_BUILD} \
                        wine-${WINE_BRANCH}=${WINE_BUILD} \
                        winehq-${WINE_BRANCH}=${WINE_BUILD}; \
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