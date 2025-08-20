# Python image for AMP containers including Python 3.10, 3.11 (default) and 3.12
# ghcr.io/cubecoders/amp:python-3

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

FROM        python:3.11-slim-bookworm AS py311

RUN         set -eux; \
            V=3.11; \
            P=/usr/local/bin/python$V; \
            D=/usr/local/lib/python$V/lib-dynload; \
            { ldd "$P"; find "$D" -type f -name '*.so' -print0 | xargs -0 -n1 ldd; } \
            | awk '/=> \//{print $(NF-1)} /^\//{print $1}' \
            | awk 'index($0,"/usr/local/")!=1 && $0 ~ "^/(usr/)?lib"' \
            | sed -E 's,^/(usr/)?,,g' | sort -u > /tmp/paths-$V.txt; \
            xargs -r dpkg-query --search < /tmp/paths-$V.txt \
            | awk -F: 'NF{print $1}' | sort -u > /tmp/deps-$V.txt; \
            echo "Runtime packages:" && cat /tmp/deps-$V.txt

FROM        python:3.12-slim-bookworm AS py312

RUN         set -eux; \
            V=3.12; \
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
COPY        --from=py311 /tmp/deps-3.11.txt /deps/3.11.txt
COPY        --from=py312 /tmp/deps-3.12.txt /deps/3.12.txt

RUN         set -eux; \
            apt-get update; \
            apt-get purge -y --auto-remove python3\*; \
            awk '{ if (!($0 in seen)) { print; seen[$0] } }' /deps/*.txt > /deps/all.txt; \
            sort -u -o /deps/all.txt /deps/all.txt; \
            xargs -r apt-get install -y --no-install-recommends < /deps/all.txt; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*

# Drop in Python 3.10
COPY        --from=py310 /usr/local/lib/ /usr/local/lib/
COPY        --from=py310 /usr/local/bin/ /usr/local/bin/

# Drop in Python 3.12
COPY        --from=py312 /usr/local/lib/ /usr/local/lib/
COPY        --from=py312 /usr/local/bin/ /usr/local/bin/

# Drop in Python 3.11
COPY        --from=py311 /usr/local/lib/ /usr/local/lib/
COPY        --from=py311 /usr/local/bin/ /usr/local/bin/

# Make explicit version shims available in /usr/bin, and make 3.11 default
RUN         set -eux; \
            for src in idle3 pip3 pydoc3 python3 python3-config; do \
                dst="$(echo "$src" | tr -d 3)"; \
                [ -e "/usr/local/bin/$dst" ] || ln -s "/usr/local/bin/$src" "/usr/local/bin/$dst"; \
            done; \
            for shim in python3.11 python3.10 python3.12 python3 pip3.11 pip3.10 pip3.12 pip3 pip; do \
                ln -sf "/usr/local/bin/$shim" "/usr/bin/$shim"; \
            done