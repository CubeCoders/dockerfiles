# Base Ubuntu 24.04 image for AMP containers
# cubecoders/ampbase:ubuntu

FROM        ubuntu:noble

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH

# Update base packages and install dependencies
RUN         set -eux; \
            mkdir -p /usr/share/man/man1; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y \
                ca-certificates curl wget tar unzip xz-utils bzip2 \
                coreutils procps iproute2 iputils-ping socat jq git git-lfs gnupg tmux dbus \
                tini tzdata locales gosu \
                libssl3t64 libcurl4t64 libsqlite3-0 libzstd1 libsdl2-2.0-0 libsdl1.2debian libfontconfig1 \
                # Required for Core Keeper
                xvfb xauth libxi6 \
                # Required for Valheim crossplay (and variously some others)
                libc6 libatomic1 libpulse0 libpulse-mainloop-glib0 \
                # Required for BeamMP
                liblua5.3-0 \
                # Required for Eco
                libgdiplus \
                # Required for Pavlov VR (and variously some others)
                gdb libc++1 libc++abi1 libunwind8 libgcc-s1; \
            \  
            case "$TARGETARCH" in \
                amd64) \
                    dpkg --add-architecture i386; \
                    apt-get update; \
                    apt-get install -o APT::Keep-Downloaded-Packages="false" -y \
                        # Required for steamcmd
                        libgcc-s1:i386 \
                        # Others
                        libstdc++6:i386 zlib1g:i386 libbz2-1.0:i386 libcurl4t64:i386 libcurl3t64-gnutls:i386 \
                        libncurses6:i386 libtinfo6:i386 libsdl2-2.0-0:i386 libssl3t64:i386; \
                    ;; \
                \
                arm64) \
                    dpkg --add-architecture armhf; \
                    apt-get update; \
                    apt-get install -o APT::Keep-Downloaded-Packages="false" -y \
                        # Required for steamcmd
                        libgcc-s1:armhf \
                        # Others
                        libstdc++6:armhf zlib1g:armhf libbz2-1.0:armhf libcurl4t64:armhf libcurl3t64-gnutls:armhf \
                        libncurses6:armhf libtinfo6:armhf libsdl2-2.0-0:armhf libssl3t64:armhf; \
                    \
                    # Add box86/box64
                    install -d -m 0755 /etc/apt/keyrings; \
                    wget -qO- "https://pi-apps-coders.github.io/box86-debs/KEY.gpg" | gpg --dearmor -o /etc/apt/keyrings/box86-archive-keyring.gpg; \
                    printf "Types: deb\nURIs: https://Pi-Apps-Coders.github.io/box86-debs/debian\nSuites: ./\nSigned-By: /etc/apt/keyrings/box86-archive-keyring.gpg" | tee /etc/apt/sources.list.d/box86.sources >/dev/null; \
                    wget -qO- "https://pi-apps-coders.github.io/box64-debs/KEY.gpg" | gpg --dearmor -o /etc/apt/keyrings/box64-archive-keyring.gpg; \
                    printf "Types: deb\nURIs: https://Pi-Apps-Coders.github.io/box64-debs/debian\nSuites: ./\nSigned-By: /etc/apt/keyrings/box64-archive-keyring.gpg" | tee /etc/apt/sources.list.d/box64.sources >/dev/null; \
                    apt-get update; \
                    apt-get install -o APT::Keep-Downloaded-Packages="false" -y \
                        box86-generic-arm:armhf box64-generic-arm; \
                    ;; \
            esac; \
            \
            # Temp fix if libssl1.1 needed
            case "${TARGETARCH}" in \
                amd64) wget -qO libssl1.1.deb https://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.24_amd64.deb;; \
                arm64) wget -qO libssl1.1.deb https://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.24_arm64.deb;; \
            esac; \
            apt-get install -y ./libssl1.1.deb; \
            rm libssl1.1.deb; \
            \
            # Install AMP instance manager
            case "${TARGETARCH}" in \
                amd64) wget -q https://cdn-repo.c7rs.com/ampinstmgr-latest.tgz;; \
                arm64) wget -q https://cdn-repo.c7rs.com/aarch64/ampinstmgr-latest.tgz;; \
            esac; \
            tar -xzf ampinstmgr-latest.tgz -C /; \
            rm ampinstmgr-latest.tgz; \
            \
            # Set up locales
            sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen; \
            locale-gen; \
            \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*

ENV         LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"

STOPSIGNAL  SIGINT

COPY        ./scripts/base/ampstart.sh /ampstart.sh
RUN         chmod +x /ampstart.sh
ENTRYPOINT  ["/usr/bin/tini", "-g", "--", "/ampstart.sh"]
CMD         []
