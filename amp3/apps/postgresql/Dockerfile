# syntax=docker/dockerfile:1

ARG         AMPBASE="cubecoders/amp3base:debian"
FROM        ${AMPBASE}

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses="MIT"
LABEL       org.opencontainers.image.title="AMPBase v3 (PostgreSQL build dependencies)"
LABEL       org.opencontainers.image.description="AMPBase v3 plus what is needed to build PostgreSQL from source. Contains no AMP code."

ENV         DEBIAN_FRONTEND="noninteractive"

RUN         set -eux; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                build-essential make tar gzip bzip2 xz-utils \
                flex bison perl pkgconf libreadline-dev zlib1g-dev libicu-dev \
                libssl-dev gettext; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*
