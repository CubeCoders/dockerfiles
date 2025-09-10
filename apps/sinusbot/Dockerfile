# SinusBot dependencies image for AMP containers
# cubecoders/ampbase:sinusbot

FROM        cubecoders/ampbase:debian

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

# Install required packages
RUN         set -eux; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                x11vnc xvfb libxcursor1 ca-certificates curl bzip2 libnss3 libegl1 x11-xkb-utils libasound2t64 libpci3 libxslt1.1 libxkbcommon0 libxss1 libxcomposite1 libglib2.0-0t64 less; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*