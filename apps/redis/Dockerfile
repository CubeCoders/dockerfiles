# Redis dependencies image for AMP containers
# cubecoders/ampbase:redis

FROM        cubecoders/ampbase:ubuntu

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

# Install dependencies as per official Redis build instructions
RUN         set -eux; \
            apt-get update; \ 
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                ca-certificates wget dpkg-dev gcc g++ libc6-dev libssl-dev make git cmake python3 \
                python3-pip python3-venv python3-dev unzip rsync clang automake autoconf libtool pkg-config; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*