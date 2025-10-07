# Python image for AMP containers including Python 3.10, 3.11, 3.12, 3.13 (default) and 3.14 from upstream
# cubecoders/ampbase:python-3

FROM        python:3.10-slim-trixie AS py310

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         PYTHON_VERSION="3.10"

COPY        scripts/python/find-deps.sh /usr/local/bin/find-deps.sh
RUN         chmod +x /usr/local/bin/find-deps.sh

RUN         set -eux; \
            /usr/local/bin/find-deps.sh >/tmp/${PYTHON_VERSION}-run-deps.txt
            
FROM        python:3.11-slim-trixie AS py311

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         PYTHON_VERSION="3.11"

COPY        scripts/python/find-deps.sh /usr/local/bin/find-deps.sh
RUN         chmod +x /usr/local/bin/find-deps.sh

RUN         set -eux; \
            /usr/local/bin/find-deps.sh >/tmp/${PYTHON_VERSION}-run-deps.txt

FROM        python:3.12-slim-trixie AS py312

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         PYTHON_VERSION="3.12"

COPY        scripts/python/find-deps.sh /usr/local/bin/find-deps.sh
RUN         chmod +x /usr/local/bin/find-deps.sh

RUN         set -eux; \
            /usr/local/bin/find-deps.sh >/tmp/${PYTHON_VERSION}-run-deps.txt

FROM        python:3.14-slim-trixie AS py314

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         PYTHON_VERSION="3.14"

COPY        scripts/python/find-deps.sh /usr/local/bin/find-deps.sh
RUN         chmod +x /usr/local/bin/find-deps.sh

RUN         set -eux; \
            /usr/local/bin/find-deps.sh >/tmp/${PYTHON_VERSION}-run-deps.txt
            
FROM        python:3.13-slim-trixie AS py313

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         PYTHON_VERSION="3.13"

COPY        scripts/python/find-deps.sh /usr/local/bin/find-deps.sh
RUN         chmod +x /usr/local/bin/find-deps.sh

RUN         set -eux; \
            /usr/local/bin/find-deps.sh >/tmp/${PYTHON_VERSION}-run-deps.txt
   
FROM        cubecoders/ampbase:debian
LABEL       org.opencontainers.image.licenses=MIT

ENV         PIP_DISABLE_PIP_VERSION_CHECK="1"
ENV         AMP_ADDITIONAL_ENV_VARS="PIP_DISABLE_PIP_VERSION_CHECK"
ENV         DEBIAN_FRONTEND="noninteractive"

ARG         PYTHON_DEFAULT="3.13"
ARG         PYTHON_NON_DEFAULT="3.10 3.11 3.12 3.14"

# Drop in upstream Python 3.10
COPY        --from=py310 /usr/local/ /usr/local/

COPY        --from=py310 /tmp/3.10-run-deps.txt /tmp/3.10-run-deps.txt

# Drop in upstream Python 3.11
COPY        --from=py311 /usr/local/ /usr/local/

COPY        --from=py311 /tmp/3.11-run-deps.txt /tmp/3.11-run-deps.txt

# Drop in upstream Python 3.12
COPY        --from=py312 /usr/local/ /usr/local/

COPY        --from=py312 /tmp/3.12-run-deps.txt /tmp/3.12-run-deps.txt

# Drop in upstream Python 3.14
COPY        --from=py314 /usr/local/ /usr/local/

COPY        --from=py314 /tmp/3.14-run-deps.txt /tmp/3.14-run-deps.txt

# Drop in upstream Python 3.13 (default last)
COPY        --from=py313 /usr/local/ /usr/local/

COPY        --from=py313 /tmp/3.13-run-deps.txt /tmp/3.13-run-deps.txt

RUN         set -eux; \
            apt-get update; \
            # Purge system Python binaries and libs
            PYTHON_PKGS="$(dpkg-query -W -f='${binary:Package}\n' \
            | awk '/^(python3($|[.:_-])|libpython3($|[.:_-]))/ {print}' \
            | sort -u)"; \
            printf '%s\n' "${PYTHON_PKGS}" | xargs -r apt-get purge --auto-remove -y; \
            \
            sort -u /tmp/*-run-deps.txt \
            | awk 'NF && $1 !~ /^#/' \
            | xargs -r apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/* /tmp/*-run-deps.txt; \
            \
            for v in ${PYTHON_NON_DEFAULT}; do \  
                python${v} -m pip install --no-cache-dir --upgrade pip setuptools wheel; \
                for shim in python${v} pip${v}; do \
                    [ -x "/usr/local/bin/${shim}" ] && ln -sf "/usr/local/bin/${shim}" "/usr/bin/${shim}"; \
                done; \
            done; \
            python${PYTHON_DEFAULT} -m pip install --no-cache-dir --upgrade pip setuptools wheel; \
            for shim in python python3 python${PYTHON_DEFAULT} pip pip3 pip${PYTHON_DEFAULT}; do \
                ln -sf "/usr/local/bin/${shim}" "/usr/bin/${shim}"; \
            done