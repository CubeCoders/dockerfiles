# syntax=docker/dockerfile:1

ARG         AMPBASE="cubecoders/amp3base:debian"
FROM        ${AMPBASE}

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses="MIT"
LABEL       org.opencontainers.image.title="AMPBase v3 (Mono)"
LABEL       org.opencontainers.image.description="AMPBase v3 plus the official Mono build. Contains no AMP code."

ENV         DEBIAN_FRONTEND="noninteractive"

RUN         set -eux; \
            # The Mono repository key is SHA1-era; extend the expiry or apt refuses it.
            install -d -m 0755 /etc/crypto-policies/back-ends; \
            cp /usr/share/apt/default-sequoia.config /etc/crypto-policies/back-ends/apt-sequoia.config; \
            sed -i \
            's/^sha1\.second_preimage_resistance.*/sha1.second_preimage_resistance = 2035-02-01/' \
            /etc/crypto-policies/back-ends/apt-sequoia.config; \
            \
            # stable-buster is the newest suite upstream publishes.
            install -d -m 0755 /etc/apt/keyrings; \
            wget -qO- "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF" | gpg --dearmor -o /etc/apt/keyrings/mono-official-archive-keyring.gpg; \
            printf 'Types: deb\nURIs: https://download.mono-project.com/repo/debian\nSuites: stable-buster\nComponents: main\nSigned-By: /etc/apt/keyrings/mono-official-archive-keyring.gpg\n' | tee /etc/apt/sources.list.d/mono-official-stable.sources >/dev/null; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y \
                mono-complete; \
            \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*
