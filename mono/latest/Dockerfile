# Mono image for AMP containers
# ghcr.io/cubecoders/amp:mono-latest

FROM        ghcr.io/cubecoders/amp:debian

LABEL       org.opencontainers.image.licenses=MIT

ARG         DEBIAN_FRONTEND=noninteractive

# Install required packages and Mono
RUN         set -eux; \
            install -d -m 0755 /etc/apt/keyrings; \
            wget -qO /etc/apt/keyrings/mono-official-archive-keyring.gpg https://download.mono-project.com/repo/xamarin.gpg; \
            printf 'Types: deb\nURIs: https://download.mono-project.com/repo/debian\nSuites: stable-buster\nComponents: main\nSigned-By: /etc/apt/keyrings/mono-official-archive-keyring.gpg\n' | tee /etc/apt/sources.list.d/mono-official-stable.sources >/dev/null; \
            apt-get update; \
            apt-get install -y mono-complete; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*