# syntax=docker/dockerfile:1

ARG         BASE_IMAGE="debian:trixie-slim"
FROM        ${BASE_IMAGE}

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses="MIT"
LABEL       org.opencontainers.image.title="AMPBase v3"
LABEL       org.opencontainers.image.description="Dependency base image for AMP3 contained shards. Contains no AMP code."

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH

# Per-distro package names, set per tag by images.json.
ARG         T64="t64"
ARG         LIBICU="libicu76"
ARG         LEGACY_NCURSES=""

RUN         set -eux; \
            # The Ubuntu bases ship a user at uid 1000, which the host amp uid would resolve to under keep-id.
            if id ubuntu >/dev/null 2>&1; then userdel -r ubuntu; fi; \
            mkdir -p /usr/share/man/man1; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y \
                ca-certificates curl wget tar unzip xz-utils bzip2 \
                coreutils procps iproute2 iputils-ping socat jq git git-lfs gnupg tmux dbus \
                tini tzdata locales gosu \
                libssl3${T64} libcurl4${T64} libsqlite3-0 libzstd1 libsdl2-2.0-0 libsdl1.2debian libfontconfig1 ${LIBICU} \
                # Required for Proton
                python3 \
                # Required for Core Keeper
                xvfb xauth libxi6 \
                # Required for Valheim crossplay (and variously some others)
                libc6 libatomic1 libpulse0 libpulse-mainloop-glib0 \
                # Required for BeamMP
                liblua5.3-0 \
                # Required for Eco
                libgdiplus \
                # Required for Pavlov VR (and variously some others)
                gdb libc++1 libc++abi1 libunwind8 libgcc-s1 \
                # Required for gateway mode
                wireguard-tools wireguard-go libcap2-bin; \
            \
            case "$TARGETARCH" in \
                amd64) \
                    dpkg --add-architecture i386; \
                    LEGACY=""; for p in ${LEGACY_NCURSES}; do LEGACY="${LEGACY} ${p}:i386"; done; \
                    apt-get update; \
                    apt-get install -o APT::Keep-Downloaded-Packages="false" -y \
                        # Required for steamcmd
                        libgcc-s1:i386 \
                        # Others
                        libstdc++6:i386 zlib1g:i386 libbz2-1.0:i386 libcurl4${T64}:i386 libcurl3${T64}-gnutls:i386 \
                        libncurses6:i386 libtinfo6:i386 libsdl2-2.0-0:i386 libssl3${T64}:i386 ${LEGACY}; \
                    ;; \
                \
                arm64) \
                    dpkg --add-architecture armhf; \
                    LEGACY=""; for p in ${LEGACY_NCURSES}; do LEGACY="${LEGACY} ${p}:armhf"; done; \
                    apt-get update; \
                    apt-get install -o APT::Keep-Downloaded-Packages="false" -y \
                        # Required for steamcmd
                        libgcc-s1:armhf \
                        # Others
                        libstdc++6:armhf zlib1g:armhf libbz2-1.0:armhf libcurl4${T64}:armhf libcurl3${T64}-gnutls:armhf \
                        libncurses6:armhf libtinfo6:armhf libsdl2-2.0-0:armhf libssl3${T64}:armhf ${LEGACY}; \
                    \
                    # box86/box64 for x86 titles on aarch64
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
            # Some older Steam titles still link libssl1.1; provide it (not in trixie).
            case "${TARGETARCH}" in \
                amd64) wget -qO libssl1.1.deb https://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.24_amd64.deb;; \
                arm64) wget -qO libssl1.1.deb https://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.24_arm64.deb;; \
            esac; \
            apt-get install -y ./libssl1.1.deb; \
            rm libssl1.1.deb; \
            \
            # Locales (en_US.UTF-8)
            sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen; \
            locale-gen; \
            \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*

ENV         LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"

# Root-only preparation; the entrypoint runs unprivileged.
RUN         set -eux; \
            # Ubuntu's images ship an empty /etc/machine-id, which dbus-uuidgen refuses to fill.
            rm -f /etc/machine-id /var/lib/dbus/machine-id; \
            dbus-uuidgen --ensure=/etc/machine-id; \
            mkdir -p /var/lib/dbus; \
            ln -sf /etc/machine-id /var/lib/dbus/machine-id; \
            chmod 0444 /etc/machine-id; \
            install -d -m 1777 /tmp/.X11-unix; \
            install -d -m 0777 /home/amp

ENV         HOME="/home/amp"

COPY        scripts/base/ampstart.sh /ampstart.sh
RUN         chmod +x /ampstart.sh
ENTRYPOINT  ["/usr/bin/tini", "--", "/ampstart.sh"]
CMD         []
