# PostgreSQL dependencies image for AMP containers
# cubecoders/ampbase:postgresql

FROM        cubecoders/ampbase:debian

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

# Install required packages
RUN         set -eux; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                build-essential make tar gzip bzip2 xz-utils \
                flex bison perl pkgconf libreadline-dev zlib1g-dev libicu-dev \
                libssl-dev gettext; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*