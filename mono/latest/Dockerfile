# Mono image for AMP containers
# ghcr.io/cubecoders/amp:mono-latest

FROM        ghcr.io/cubecoders/amp:debian

LABEL       org.opencontainers.image.licenses=MIT

ARG         DEBIAN_FRONTEND="noninteractive"

# Install required packages and Mono
RUN         set -eux; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                dirmngr; \
            \
            install -d -m 0755 /etc/apt/keyrings; \
            gpg --homedir /tmp --no-default-keyring --keyring /etc/apt/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF; \
            printf 'Types: deb\nURIs: https://download.mono-project.com/repo/debian\nSuites: stable-buster\nComponents: main\nSigned-By: /etc/apt/keyrings/mono-official-archive-keyring.gpg\n' | tee /etc/apt/sources.list.d/mono-official-stable.sources >/dev/null; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y \
                mono-complete; \
            \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*