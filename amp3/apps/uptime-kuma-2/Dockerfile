# syntax=docker/dockerfile:1

ARG         AMPBASE="cubecoders/amp3base:debian"
FROM        ${AMPBASE}

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses="MIT"
LABEL       org.opencontainers.image.title="AMPBase v3 (Uptime Kuma 2 dependencies)"
LABEL       org.opencontainers.image.description="AMPBase v3 plus the dependencies Uptime Kuma 2 needs, including its embedded MariaDB. Contains no AMP code."

ENV         UPTIME_KUMA_ENABLE_EMBEDDED_MARIADB="1"
ENV         AMP_ADDITIONAL_ENV_VARS="UPTIME_KUMA_ENABLE_EMBEDDED_MARIADB"
ENV         DEBIAN_FRONTEND="noninteractive"

RUN         set -eux; \
            apt-get update; \
            # Install base dependencies
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                sqlite3 ca-certificates iputils-ping util-linux; \
            # Install Apprise for notifications
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                apprise python3-paho-mqtt; \
            # Install cloudflared
            install -d -m 0755 /etc/apt/keyrings; \
            wget -qO- https://pkg.cloudflare.com/cloudflare-main.gpg | gpg --dearmor -o /etc/apt/keyrings/cloudflare-main.gpg; \
            printf 'Types: deb\nURIs: https://pkg.cloudflare.com/cloudflared\nSuites: any\nComponents: main\nSigned-By: /etc/apt/keyrings/cloudflare-main.gpg\n' | tee /etc/apt/sources.list.d/cloudflared.sources >/dev/null; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends -t stable \
                cloudflared; \
            # Install remaining dependencies
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                chromium fonts-indic fonts-noto fonts-noto-cjk mariadb-server; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*; \
            \
            # Writable by any uid; the entrypoint has no root.
            install -d -m 0777 /run/mysqld; \
            chmod -R a+rwX /var/lib/mysql
