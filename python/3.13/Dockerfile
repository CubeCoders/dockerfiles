# Python image for AMP containers using Python 3.13 from upstream
# ghcr.io/cubecoders/amp:python-3.13

FROM        python:3.13-slim-bookworm AS py313

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         PYTHON_VERSION="3.13"

COPY        scripts/python/find-deps.sh /usr/local/bin/find-deps.sh
RUN         chmod +x /usr/local/bin/find-deps.sh

RUN         set -eux; \
            /usr/local/bin/find-deps.sh ${PYTHON_VERSION} >/tmp/${PYTHON_VERSION}-run-deps.txt

FROM        ghcr.io/cubecoders/amp:debian
LABEL       org.opencontainers.image.licenses=MIT

ENV         PIP_DISABLE_PIP_VERSION_CHECK="1"
ENV         DEBIAN_FRONTEND="noninteractive"

ARG         PYTHON_VERSION="3.13"

# Drop in upstream Python 3.13
COPY        --from=py313 /usr/local/ /usr/local/

COPY        --from=py313 /tmp/${PYTHON_VERSION}-run-deps.txt /tmp/${PYTHON_VERSION}-run-deps.txt

RUN         set -eux; \
            apt-get update; \
            # Purge system Python binaries and libs
            PYTHON_PKGS="$(dpkg-query -W -f='${binary:Package}\n' \
            | awk '/^(python3($|[.:_-])|libpython3($|[.:_-]))/ {print}' \
            | sort -u)"; \
            printf '%s\n' "${PYTHON_PKGS}" | xargs -r apt-get purge --auto-remove -y; \
            \
            sort -u /tmp/${PYTHON_VERSION}-run-deps.txt \
            | awk 'NF && $1 !~ /^#/' \
            | xargs -r apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/* /tmp/${PYTHON_VERSION}-run-deps.txt; \
            \
            python${PYTHON_VERSION} -m pip install --no-cache-dir --upgrade pip setuptools wheel; \
            for shim in python python3 python${PYTHON_VERSION} pip pip3 pip${PYTHON_VERSION}; do \
                ln -sf "/usr/local/bin/${shim}" "/usr/bin/${shim}"; \
            done