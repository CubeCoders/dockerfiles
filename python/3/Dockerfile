# Python image for AMP containers including Python 3.10, 3.11 and 3.12
# ghcr.io/cubecoders/amp:python-3

FROM        python:3.10-slim-bookworm AS py310
FROM        python:3.12-slim-bookworm AS py312

FROM        ghcr.io/cubecoders/amp:debian
LABEL       org.opencontainers.image.licenses=MIT

ENV         PIP_DISABLE_PIP_VERSION_CHECK=1

ARG         DEBIAN_FRONTEND=noninteractive

# System Python (3.11) from Debian
RUN         set -eux; \
            apt-get update; \
            apt-get install -y --no-install-recommends \
                python3 python3-pip python3-venv; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*

# Drop in Python 3.10
COPY        --from=py310 /usr/local/ /usr/local/

# Drop in Python 3.12
COPY        --from=py312 /usr/local/ /usr/local/

# Make explicit version shims available in /usr/bin
RUN         ln -sf /usr/local/bin/python3.10 /usr/bin/python3.10 && \
            ln -sf /usr/local/bin/python3.12 /usr/bin/python3.12 && \
            ln -sf /usr/local/bin/pip3.10 /usr/bin/pip3.10 && \
            ln -sf /usr/local/bin/pip3.12 /usr/bin/pip3.12