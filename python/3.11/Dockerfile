# Python image for AMP containers using Python 3.11
# ghcr.io/cubecoders/amp:python-3.11

FROM        ghcr.io/cubecoders/amp:debian
LABEL       org.opencontainers.image.licenses=MIT

ENV         PIP_DISABLE_PIP_VERSION_CHECK="1"

ARG         DEBIAN_FRONTEND="noninteractive"

# System Python (3.11) from Debian
RUN         set -eux; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                python3 python3-venv python3-pip; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*