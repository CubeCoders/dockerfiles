# Java image for AMP containers including all Temurin LTS versions
# cubecoders/ampbase:java-lts

FROM        cubecoders/ampbase:debian

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

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
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*