# Mono image for AMP containers
# cubecoders/ampbase:mono-latest

FROM        cubecoders/ampbase:debian

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

# Install Mono from the Debian archive (mono-project.com repo is frozen at 6.12 for buster)
RUN         set -eux; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y \
                mono-complete; \
            \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*
