# Wine image for AMP containers
# cubecoders/ampbase:wine-${WINE_TARGET:+${WINE_TARGET}-}${WINE_BRANCH}
# WINE_BRANCH: stable | devel | staging; WINE_TARGET: optional major version to pin (e.g. 10)

FROM        cubecoders/ampbase:wine-common

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH
ARG         WINE_DIST="trixie"
ARG         WINE_BRANCH="stable"
ARG         WINE_TARGET=""

# Install additional required packages and Wine
RUN         set -eux; \
            case "${WINE_BRANCH}" in \
                staging) WINE_LINK="https://dl.winehq.org/wine-builds/debian/pool/main/w/wine-staging/";; \
                *) WINE_LINK="https://dl.winehq.org/wine-builds/debian/pool/main/w/wine/";; \
            esac; \
            WINE_BUILD="$( \
                curl -fsSL "${WINE_LINK}" \
                | grep -oE "wine-${WINE_BRANCH}-amd64_[0-9][0-9.]*(~rc[0-9]+)?~${WINE_DIST}(-[0-9]+)?_amd64\.deb" \
                | sed -E "s/^wine-${WINE_BRANCH}-amd64_([0-9][0-9.]*(~rc[0-9]+)?~${WINE_DIST}(-[0-9]+)?)_amd64\.deb$/\1/" \
                | grep -E "^${WINE_TARGET:-[0-9]+}(\.|~|$)" \
                | sort -V | tail -1 \
            )"; \
            test -n "${WINE_BUILD}"; \
            \
            install -d -m 0755 /etc/apt/keyrings; \
            wget -qO- https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -; \
            wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/${WINE_DIST}/winehq-${WINE_DIST}.sources; \
            \
            case "${TARGETARCH}" in \
            \
                amd64) \
                    apt-get update; \
                    if [ -n "${WINE_TARGET}" ]; then \
                        apt-get install -o APT::Keep-Downloaded-Packages="false" -y --install-recommends \
                            wine-${WINE_BRANCH}-i386=${WINE_BUILD} \
                            wine-${WINE_BRANCH}-amd64=${WINE_BUILD} \
                            wine-${WINE_BRANCH}=${WINE_BUILD} \
                            winehq-${WINE_BRANCH}=${WINE_BUILD}; \
                    else \
                        apt-get install -o APT::Keep-Downloaded-Packages="false" -y --install-recommends \
                            winehq-${WINE_BRANCH}; \
                    fi; \
                    ;; \
                \
                arm64) \
                    apt-get update; \
                    xargs -ra /tmp/wine-files/wine-${WINE_TARGET:+${WINE_TARGET}-}${WINE_BRANCH}-deps-arm64.txt \
                        apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends; \
                    \
                    # Fetch the x86 builds through apt so the WineHQ signature is verified, then unpack for box64
                    dpkg --add-architecture amd64; \
                    dpkg --add-architecture i386; \
                    apt-get update; \
                    (cd /tmp/wine-files && apt-get download -o APT::Sandbox::User=root \
                        wine-${WINE_BRANCH}-amd64:amd64=${WINE_BUILD} \
                        wine-${WINE_BRANCH}:amd64=${WINE_BUILD} \
                        winehq-${WINE_BRANCH}:amd64=${WINE_BUILD} \
                        wine-${WINE_BRANCH}-i386:i386=${WINE_BUILD}); \
                    dpkg --remove-architecture amd64; \
                    dpkg --remove-architecture i386; \
                    rm -f /etc/apt/sources.list.d/winehq-${WINE_DIST}.sources /etc/apt/keyrings/winehq-archive.key; \
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
