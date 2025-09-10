# MongoDB dependencies image for AMP containers
# cubecoders/ampbase:mongodb

FROM        cubecoders/ampbase:debian

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

# Install required packages
RUN         set -eux; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                libcurl4t64 libgssapi-krb5-2 libldap-common libwrap0 libsasl2-2 libsasl2-modules libsasl2-modules-gssapi-mit openssl liblzma5; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*