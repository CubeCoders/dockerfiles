# Wine image for AMP containers based on Wine devel
# cubecoders/ampbase:wine-devel

FROM        cubecoders/ampbase:wine-common

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH
ARG         WINE_DIST="trixie"
ARG         WINE_BRANCH="devel"
ARG         WINE_LINK="https://dl.winehq.org/wine-builds/debian/pool/main/w/wine/"

# Install additional required packages and Wine devel
RUN         set -eux; \
            WINE_BUILD="$( \
                curl -fsSL "${WINE_LINK}" \
                | grep -oE "wine-${WINE_BRANCH}-amd64_[0-9][0-9.]*(~rc[0-9]+)?~${WINE_DIST}(-[0-9]+)?_amd64\.deb" \
                | sed -E "s/^wine-${WINE_BRANCH}-amd64_([0-9][0-9.]*(~rc[0-9]+)?~${WINE_DIST}(-[0-9]+)?)_amd64\.deb$/\1/" \
                | sort -V | tail -1 \
                )"; \
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
                        winehq-${WINE_BRANCH}; \
                    ;; \
                \
                arm64) \
                    apt-get update; \
                    xargs -ra /tmp/wine-files/wine-${WINE_BRANCH}-deps-arm64.txt \
                        apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends; \
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
                    for file in /opt/wine-"${WINE_BRANCH}"/bin/*; do \
                        [ -x "${file}" ] && ln -sf "${file}" /usr/bin/"$(basename "${file}")"; \
                    done; \
                    ;; \
            esac; \
            \
            rm -rf /tmp/wine-files; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*
