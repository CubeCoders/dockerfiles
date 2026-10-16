# Python image for AMP containers using a single Python version from upstream
# cubecoders/ampbase:python-${PYTHON_VERSION} (build with --build-arg PYTHON_VERSION=3.x)

ARG         PYTHON_VERSION="3.13"

FROM        python:${PYTHON_VERSION}-slim-trixie AS py

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         PYTHON_VERSION

COPY        scripts/python/find-deps.sh /usr/local/bin/find-deps.sh
RUN         chmod +x /usr/local/bin/find-deps.sh

RUN         set -eux; \
            /usr/local/bin/find-deps.sh >/tmp/${PYTHON_VERSION}-run-deps.txt

FROM        cubecoders/ampbase:debian
LABEL       org.opencontainers.image.licenses=MIT

ENV         PIP_DISABLE_PIP_VERSION_CHECK="1"
ENV         AMP_ADDITIONAL_ENV_VARS="PIP_DISABLE_PIP_VERSION_CHECK"
ENV         DEBIAN_FRONTEND="noninteractive"

ARG         PYTHON_VERSION

# Drop in upstream Python
COPY        --from=py /usr/local/ /usr/local/

COPY        --from=py /tmp/${PYTHON_VERSION}-run-deps.txt /tmp/${PYTHON_VERSION}-run-deps.txt

RUN         set -eux; \
            apt-get update; \
            # Purge system Python binaries and libs
            PYTHON_PKGS="$(dpkg-query -W -f='${binary:Package}\n' \
            | awk '/^(python3($|[.:_-])|libpython3($|[.:_-]))/ {print}' \
            | sort -u)"; \
            printf '%s\n' "${PYTHON_PKGS}" | xargs -r apt-get purge --auto-remove -y; \
            \
            # Reinstall gdb (base image dependency) which the purge removes via libpython3
            sort -u /tmp/${PYTHON_VERSION}-run-deps.txt \
            | awk 'NF && $1 !~ /^#/' \
            | xargs -r apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends gdb; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/* /tmp/${PYTHON_VERSION}-run-deps.txt; \
            \
            python${PYTHON_VERSION} -m pip install --no-cache-dir --upgrade pip setuptools wheel; \
            for shim in python python3 python${PYTHON_VERSION} pip pip3 pip${PYTHON_VERSION}; do \
                ln -sf "/usr/local/bin/${shim}" "/usr/bin/${shim}"; \
            done
