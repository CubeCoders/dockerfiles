# syntax=docker/dockerfile:1

ARG         AMPBASE="cubecoders/amp3base:debian"
ARG         PYTHON_VERSION="3.13"

# Upstream image: source of /usr/local and of the packages it links against.
FROM        python:${PYTHON_VERSION}-slim-trixie AS upstream

ENV         DEBIAN_FRONTEND="noninteractive"

COPY        scripts/python/find-deps.sh /usr/local/bin/find-deps.sh
RUN         set -eux; \
            chmod +x /usr/local/bin/find-deps.sh; \
            /usr/local/bin/find-deps.sh >/tmp/run-deps.txt; \
            rm /usr/local/bin/find-deps.sh

FROM        ${AMPBASE}

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses="MIT"
LABEL       org.opencontainers.image.title="AMPBase v3 (Python)"
LABEL       org.opencontainers.image.description="AMPBase v3 plus an official upstream Python build. Contains no AMP code."

ENV         PIP_DISABLE_PIP_VERSION_CHECK="1"
ENV         AMP_ADDITIONAL_ENV_VARS="PIP_DISABLE_PIP_VERSION_CHECK"
ENV         DEBIAN_FRONTEND="noninteractive"

# An ARG declared before the first FROM is out of scope inside a stage until redeclared.
ARG         PYTHON_VERSION

# Drop in upstream Python
COPY        --from=upstream /usr/local/ /usr/local/
COPY        --from=upstream /tmp/run-deps.txt /tmp/run-deps.txt

RUN         set -eux; \
            apt-get update; \
            # Purge the system Python
            PYTHON_PKGS="$(dpkg-query -W -f='${binary:Package}\n' \
            | awk '/^(python3($|[.:_-])|libpython3($|[.:_-]))/ {print}' \
            | sort -u)"; \
            printf '%s\n' "${PYTHON_PKGS}" | xargs -r apt-get purge --auto-remove -y; \
            \
            sort -u /tmp/run-deps.txt \
            | awk 'NF && $1 !~ /^#/' \
            | xargs -r apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/* /tmp/run-deps.txt; \
            \
            python${PYTHON_VERSION} -m pip install --no-cache-dir --upgrade pip setuptools wheel; \
            for shim in python python3 python${PYTHON_VERSION} pip pip3 pip${PYTHON_VERSION}; do \
                ln -sf "/usr/local/bin/${shim}" "/usr/bin/${shim}"; \
            done
