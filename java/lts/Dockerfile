# Java image for AMP containers including all Temurin LTS versions
# ghcr.io/cubecoders/amp:java-lts

FROM        ghcr.io/cubecoders/amp:debian

LABEL       org.opencontainers.image.licenses=MIT

ARG         DEBIAN_FRONTEND=noninteractive

# Install required packages and Temurin Java LTS versions
RUN         set -eux; \
            apt-get update; \
            apt-get install -y --no-install-recommends fontconfig fonts-dejavu-core; \
            install -d -m 0755 /etc/apt/keyrings; \
            wget -qO- https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg; \
            echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list >/dev/null; \
            apt-get update; \
            apt-get install -y temurin-8-jdk temurin-11-jdk temurin-17-jdk temurin-21-jdk; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*