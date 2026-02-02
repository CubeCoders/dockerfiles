# Mono image for AMP containers
# cubecoders/ampbase:mono-latest

FROM        cubecoders/ampbase:debian

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

# Install required packages and Mono
RUN         set -eux; \
            # Extend SHA1 algorithm expiry date as per /usr/share/apt/default-sequoia.config
            install -d -m 0755 /etc/crypto-policies/back-ends; \
            cp /usr/share/apt/default-sequoia.config /etc/crypto-policies/back-ends/apt-sequoia.config; \
            sed -i \
            's/^sha1\.second_preimage_resistance.*/sha1.second_preimage_resistance = 2035-02-01/' \
            /etc/crypto-policies/back-ends/apt-sequoia.config; \
            \
            # Add Mono repository and install Mono
            install -d -m 0755 /etc/apt/keyrings; \
            wget -qO- "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF" | gpg --dearmor -o /etc/apt/keyrings/mono-official-archive-keyring.gpg; \
            printf 'Types: deb\nURIs: https://download.mono-project.com/repo/debian\nSuites: stable-buster\nComponents: main\nSigned-By: /etc/apt/keyrings/mono-official-archive-keyring.gpg\n' | tee /etc/apt/sources.list.d/mono-official-stable.sources >/dev/null; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y \
                mono-complete; \
            \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*