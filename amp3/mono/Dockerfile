# syntax=docker/dockerfile:1

ARG         AMPBASE="cubecoders/amp3base:debian"
FROM        ${AMPBASE}

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses="MIT"
LABEL       org.opencontainers.image.title="AMPBase v3 (Mono)"
LABEL       org.opencontainers.image.description="AMPBase v3 plus Mono from the Debian archive. Contains no AMP code."

ENV         DEBIAN_FRONTEND="noninteractive"

# The mono-project.com repository is frozen at buster; the Debian archive is maintained.
RUN         set -eux; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                mono-complete; \
            \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*
