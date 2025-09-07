# PostgreSQL image for AMP containers
# cubecoders/ampbase:postgresql

FROM        cubecoders/ampbase:debian

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

# Install required packages
RUN         set -eux; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                make build-essential flex bison perl libreadline-dev libicu-dev; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*