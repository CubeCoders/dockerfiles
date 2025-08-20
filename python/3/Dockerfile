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
                python3.11 python3.11-venv python3-pip; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*

# Drop in Python 3.10
COPY        --from=py310 /usr/local/lib/ /usr/local/lib/
COPY        --from=py310 /usr/local/bin/ /usr/local/bin/

# Drop in Python 3.12
COPY        --from=py312 /usr/local/lib/ /usr/local/lib/
COPY        --from=py312 /usr/local/bin/ /usr/local/bin/

# Clean up
RUN         set -eux; \
            python3.10 -m pip --no-cache-dir install --upgrade pip setuptools wheel; \
            python3.12 -m pip --no-cache-dir install --upgrade pip setuptools wheel; \
            for shim in python3.10 python3.12 pip3.10 pip3.12; do \
                ln -sf "/usr/local/bin/$shim" "/usr/bin/$shim"; \
            done; \
            for shim in pip pip3 idle3 pydoc3 2to3 python-config python3-config; do \
                rm -f "/usr/local/bin/$shim"; \
            done