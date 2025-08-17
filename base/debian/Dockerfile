# Base Debian 12 image for AMP containers
# ghcr.io/cubecoders/amp:debian

FROM        debian:bookworm-slim

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses=MIT

ENV         AMP_CONTAINER="DOCKER"
ENV         LD_LIBRARY_PATH="./:/opt/cubecoders/amp/:/AMP/"

ARG         DEBIAN_FRONTEND=noninteractive
ARG         TARGETARCH

# Update base packages and install dependencies, including temp fix if libssl1.1 needed
RUN         set -eux; \
            mkdir -p /usr/share/man/man1; \
            apt-get update; \
            apt-get install -y --no-install-recommends \
                ca-certificates software-properties-common curl wget tar unzip xz-utils bzip2 \
                coreutils procps net-tools iproute2 iputils-ping socat jq git git-lfs gnupg lsof tmux sqlite3 gdb \
                tini tzdata locales \
                xvfb xauth libxi6 \
                libc6 libc++-dev libcurl4 libatomic1 libpulse-dev liblua5.3-0 libfontconfig1 libgdiplus libsqlite3-0 libzstd1 libsdl2-2.0-0 libsdl1.2-compat; \
            if [ "$TARGETARCH" = "amd64" ]; then \
                dpkg --add-architecture i386; \
                apt-get update; \
                apt-get install -y --no-install-recommends \
                    libc6:i386 libstdc++6:i386 libgcc-s1:i386 zlib1g:i386 libbz2-1.0:i386 libzstd1:i386 libcurl4:i386 libcurl3-gnutls:i386 libcurl4-gnutls-dev:i386 \
                    libtinfo6:i386 libncurses6:i386 libncurses5:i386 libtinfo5:i386 libsdl2-2.0-0:i386 libsdl1.2-compat:i386 libssl-dev:i386; \
            fi; \
            case "$TARGETARCH" in \
                amd64) wget -qO libssl1.1.deb https://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb ;; \
                arm64) wget -qO libssl1.1.deb https://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_arm64.deb ;; \
            esac; \
            apt-get install -y --no-install-recommends ./libssl1.1.deb; \
            rm libssl1.1.deb; \
            case "$TARGETARCH" in \
                amd64) wget -q https://cdn-repo.c7rs.com/ampinstmgr-latest.tgz ;; \
                arm64) wget -q https://cdn-repo.c7rs.com/aarch64/ampinstmgr-latest.tgz ;; \
            esac; \
            tar -xzf ampinstmgr-latest.tgz -C /; \
            rm ampinstmgr-latest.tgz; \
            sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen; \
            locale-gen; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*

ENV         LANG=en_US.UTF-8
ENV         LANGUAGE=en_US:en
ENV         LC_ALL=en_US.UTF-8

COPY        ./scripts/ampstart.sh /ampstart.sh
RUN         chmod +x /ampstart.sh
ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/ampstart.sh"]
