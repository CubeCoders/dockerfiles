# Python image for AMP containers using Python 3.10
# ghcr.io/cubecoders/amp:python-3.10

FROM        python:3.10-slim-bookworm AS py310

RUN         set -eux; \
            V=3.10; \
            P=/usr/local/bin/python$V; \
            D=/usr/local/lib/python$V/lib-dynload; \
            { ldd "$P"; find "$D" -type f -name '*.so' -print0 | xargs -0 -n1 ldd; } \
            | awk '/=> \//{print $(NF-1)} /^\//{print $1}' \
            | awk 'index($0,"/usr/local/")!=1 && $0 ~ "^/(usr/)?lib"' \
            | sed -E 's,^/(usr/)?,,g' | sort -u > /tmp/paths-$V.txt; \
            xargs -r dpkg-query --search < /tmp/paths-$V.txt \
            | awk -F: 'NF{print $1}' | sort -u > /tmp/deps-$V.txt; \
            echo "Runtime packages:" && cat /tmp/deps-$V.txt

FROM        ghcr.io/cubecoders/amp:debian
LABEL       org.opencontainers.image.licenses=MIT

ENV         PIP_DISABLE_PIP_VERSION_CHECK=1

ARG         DEBIAN_FRONTEND=noninteractive

COPY        --from=py310 /tmp/deps-3.10.txt /deps/3.10.txt

RUN         set -eux; \
            apt-get update; \
            apt-get purge -y --auto-remove python3\*; \
            RUNTIME_DEPS="$(cat /deps/3.10.txt)"; \
            apt-get install -y --no-install-recommends $RUNTIME_DEPS; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*

COPY        --from=py310 /usr/local/ /usr/local/

RUN         set -eux; \
            for src in idle3 pip3 pydoc3 python3 python3-config; do \
                dst="$(echo "$src" | tr -d 3)"; \
                [ -e "/usr/local/bin/$dst" ] || ln -s "/usr/local/bin/$src" "/usr/local/bin/$dst"; \
            done; \
            for shim in python3.10 python3 pip3.10 pip3 pip; do \
                ln -sf "/usr/local/bin/$shim" "/usr/bin/$shim"; \
            done
