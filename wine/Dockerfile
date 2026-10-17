# Wine image for AMP containers
# cubecoders/ampbase:wine-${WINE_TARGET:+${WINE_TARGET}-}${WINE_BRANCH}
# WINE_BRANCH: stable | devel | staging; WINE_TARGET: optional major version to pin (e.g. 10)
# WINE_BUILD: optional exact WineHQ version (CI passes it so cached Wine builds follow upstream releases)

ARG         WINE_DIST="trixie"

# WineHQ's debs per build arch; NTSYNC-capable versions are rebuilt from source (see get-wine-debs.sh)
FROM        --platform=linux/amd64 debian:${WINE_DIST} AS debs-amd64
ARG         WINE_DIST WINE_BRANCH="stable" WINE_TARGET="" WINE_BUILD=""
COPY        scripts/wine/get-wine-debs.sh /usr/local/bin/get-wine-debs.sh
RUN         sh /usr/local/bin/get-wine-debs.sh amd64

FROM        --platform=linux/386 debian:${WINE_DIST} AS debs-i386
ARG         WINE_DIST WINE_BRANCH="stable" WINE_TARGET="" WINE_BUILD=""
COPY        scripts/wine/get-wine-debs.sh /usr/local/bin/get-wine-debs.sh
RUN         sh /usr/local/bin/get-wine-debs.sh i386

FROM        cubecoders/ampbase:wine-common

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH
ARG         WINE_BRANCH="stable"
ARG         WINE_TARGET=""

# Install Wine (debs bind-mounted from the builder stages so they never land in a layer)
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
                    xargs -ra /tmp/wine-files/wine-${WINE_TARGET:+${WINE_TARGET}-}${WINE_BRANCH}-deps-arm64.txt \
                        apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends; \
                    \
                    # Unpack the x86 builds for box64
                    for d in /tmp/wine-debs/*/*.deb; do dpkg-deb -x "$d" /wine-installer; done; \
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
