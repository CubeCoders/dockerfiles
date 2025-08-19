# Wine image for AMP containers based on Wine 9 stable
# ghcr.io/cubecoders/amp:wine-9-stable

FROM        ghcr.io/cubecoders/amp:debian

LABEL       org.opencontainers.image.licenses=MIT

ARG         DEBIAN_FRONTEND=noninteractive

# Install required packages and Wine 9 stable
RUN         set -eux; \
            apt-get update; \
            apt-get install -y --no-install-recommends cabextract winbind wine-binfmt python3; \
            install -d -m 0755 /etc/apt/keyrings; \
            wget -qO- https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -; \
            wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources; \
            apt-get update; \
            apt-get install -y --install-recommends \
                wine-stable-i386=9.0.0.0~bookworm-1 \
                wine-stable-amd64=9.0.0.0~bookworm-1 \
                wine-stable=9.0.0.0~bookworm-1 \
                winehq-stable=9.0.0.0~bookworm-1; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*