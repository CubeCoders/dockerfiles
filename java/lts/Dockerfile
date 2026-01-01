# Java image for AMP containers including all Temurin LTS versions
# cubecoders/ampbase:java-lts

FROM        cubecoders/ampbase:debian

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
            wget -qO- https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg; \
            printf 'Types: deb\nURIs: https://packages.adoptium.net/artifactory/deb\nSuites: trixie\nComponents: main\nSigned-By: /etc/apt/keyrings/adoptium.gpg\n' | tee /etc/apt/sources.list.d/adoptium.sources >/dev/null; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y \
                temurin-8-jdk temurin-11-jdk temurin-17-jdk temurin-21-jdk temurin-25-jdk; \
            # Set Java 21 as the default version
            case "${TARGETARCH}" in \
                amd64) \
                    update-alternatives --set java /usr/lib/jvm/temurin-21-jdk-amd64/bin/java; \
                    update-alternatives --set javac /usr/lib/jvm/temurin-21-jdk-amd64/bin/javac; \
                ;; \
                arm64) \
                    update-alternatives --set java /usr/lib/jvm/temurin-21-jdk-arm64/bin/java; \
                    update-alternatives --set javac /usr/lib/jvm/temurin-21-jdk-arm64/bin/javac; \
                ;; \
            esac; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*