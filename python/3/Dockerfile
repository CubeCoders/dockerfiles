# Python image for AMP containers including Python 3.10, 3.11 (default) and 3.12
# ghcr.io/cubecoders/amp:python-3

FROM        python:3.10-slim-bookworm AS py310
FROM        python:3.12-slim-bookworm AS py312

FROM        ghcr.io/cubecoders/amp:python-3.11
LABEL       org.opencontainers.image.licenses=MIT

ARG         DEBIAN_FRONTEND="noninteractive"

# Drop in upstream Python 3.10
COPY        --from=py310 /usr/local/bin/python3.10 /usr/local/bin/
COPY        --from=py310 /usr/local/bin/pip3.10 /usr/local/bin/
COPY        --from=py310 /usr/local/lib/python3.10/ /usr/local/lib/python3.10/
COPY        --from=py310 /usr/local/lib/libpython3.10* /usr/local/lib/

# Drop in upstream Python 3.12
COPY        --from=py312 /usr/local/bin/python3.12 /usr/local/bin/
COPY        --from=py312 /usr/local/bin/pip3.12 /usr/local/bin/
COPY        --from=py312 /usr/local/lib/python3.12/ /usr/local/lib/python3.12/
COPY        --from=py312 /usr/local/lib/libpython3.12* /usr/local/lib/

# Clean up
RUN         set -eux; \
            python3.10 -m pip --no-cache-dir install --upgrade pip setuptools wheel; \
            python3.12 -m pip --no-cache-dir install --upgrade pip setuptools wheel; \
            for shim in python3.10 python3.12 pip3.10 pip3.12; do \
                ln -sf "/usr/local/bin/${shim}" "/usr/bin/${shim}"; \
            done