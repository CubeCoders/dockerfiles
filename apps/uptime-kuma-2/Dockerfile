# Uptime Kuma 2 dependencies image for AMP containers
# Based on https://github.com/louislam/uptime-kuma/blob/223cde831f09a49a317bc4e5926cc8a38a6fa3f2/docker/debian-base.dockerfile
# cubecoders/ampbase:uptime-kuma-2

FROM        cubecoders/ampbase:debian

LABEL       org.opencontainers.image.licenses=MIT

ENV         UPTIME_KUMA_ENABLE_EMBEDDED_MARIADB="1"
ENV         AMP_ADDITIONAL_ENV_VARS="UPTIME_KUMA_ENABLE_EMBEDDED_MARIADB"
ENV         DEBIAN_FRONTEND="noninteractive"

# Install required packages
RUN         set -eux; \
            apt-get update; \
            # Install base dependencies
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                sqlite3 ca-certificates iputils-ping util-linux; \
            # Install Apprise for notifications
            wget -qO- http://ftp.debian.org/debian/pool/main/a/apprise/ | grep -oP 'href="apprise_.*?all\.deb"' | sed 's/href="//;s/"//' | sort -V | tail -n 1 | xargs -I {} wget -qO apprise.deb http://ftp.debian.org/debian/pool/main/a/apprise/{}; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                ./apprise.deb python3-paho-mqtt; \
            rm -f apprise.deb; \
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
            rm -rf /var/lib/apt/lists/*
 
COPY        ./scripts/apps/uptime-kuma-2/ampstart.sh /ampstart.sh
RUN         chmod +x /ampstart.sh
ENTRYPOINT  ["/usr/bin/tini", "-g", "--", "/ampstart.sh"]
CMD         []
            