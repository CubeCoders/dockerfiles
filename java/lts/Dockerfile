# Java image for AMP containers including all Temurin LTS versions
# cubecoders/ampbase:java-lts

FROM        cubecoders/ampbase:debian

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

ARG         TARGETARCH

# Install required packages and Temurin Java LTS versions
RUN         set -eux; \
            apt-get update; \
            # Add dependencies as per official Adoptium images
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
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                temurin-8-jdk temurin-11-jdk temurin-17-jdk temurin-21-jdk temurin-25-jdk; \
            # Set Java 21 as the default version
            update-alternatives --set java "/usr/lib/jvm/temurin-21-jdk-${TARGETARCH}/bin/java"; \
            update-alternatives --set javac "/usr/lib/jvm/temurin-21-jdk-${TARGETARCH}/bin/javac"; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*