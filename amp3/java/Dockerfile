# syntax=docker/dockerfile:1

ARG         AMPBASE="cubecoders/amp3base:debian"
FROM        ${AMPBASE}

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses="MIT"
LABEL       org.opencontainers.image.title="AMPBase v3 (Java)"
LABEL       org.opencontainers.image.description="AMPBase v3 plus Adoptium Eclipse Temurin JDKs. Contains no AMP code."

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH
ARG         JAVA_VERSIONS="8 11 17 21 25"
ARG         JAVA_DEFAULT="21"

RUN         set -eux; \
            apt-get update; \
            # Dependencies as per the official Adoptium images
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                fontconfig binutils p11-kit; \
            install -d -m 0755 /etc/apt/keyrings; \
            wget -qO /tmp/apt.key "https://packages.adoptium.net/artifactory/api/gpg/key/public"; \
            [ "$(gpg --show-keys --with-colons /tmp/apt.key | awk -F: '$1=="pub"{p=1;next} p&&$1=="fpr"{print $10;p=0}')" = "3B04D753C9050D9A5D343F39843C48A565F8F04B" ] \
                || { echo "Unexpected signing key at https://packages.adoptium.net/artifactory/api/gpg/key/public" >&2; exit 1; }; \
            gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg /tmp/apt.key; \
            rm -rf /tmp/apt.key /root/.gnupg; \
            printf 'Types: deb\nURIs: https://packages.adoptium.net/artifactory/deb\nSuites: %s\nComponents: main\nSigned-By: /etc/apt/keyrings/adoptium.gpg\n' "$(. /etc/os-release; echo "${VERSION_CODENAME}")" | tee /etc/apt/sources.list.d/adoptium.sources >/dev/null; \
            apt-get update; \
            JAVA_PACKAGES=""; \
            for v in ${JAVA_VERSIONS}; do JAVA_PACKAGES="${JAVA_PACKAGES} temurin-${v}-jdk"; done; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                ${JAVA_PACKAGES}; \
            # Temurin names its directory by Debian arch (TARGETARCH).
            update-alternatives --set java "/usr/lib/jvm/temurin-${JAVA_DEFAULT}-jdk-${TARGETARCH}/bin/java"; \
            update-alternatives --set javac "/usr/lib/jvm/temurin-${JAVA_DEFAULT}-jdk-${TARGETARCH}/bin/javac"; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*
