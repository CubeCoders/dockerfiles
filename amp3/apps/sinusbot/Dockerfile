# syntax=docker/dockerfile:1

ARG         AMPBASE="cubecoders/amp3base:debian"
FROM        ${AMPBASE}

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses="MIT"
LABEL       org.opencontainers.image.title="AMPBase v3 (SinusBot dependencies)"
LABEL       org.opencontainers.image.description="AMPBase v3 plus the dependencies SinusBot and its TeamSpeak client need. Contains no AMP code."

ENV         DEBIAN_FRONTEND="noninteractive"

RUN         set -eux; \
            apt-get update; \
            # Purge the PulseAudio libs the base image carries.
            apt-get purge --auto-remove -y libpulse0 libpulse-mainloop-glib0; \
            \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                ca-certificates bzip2 unzip wget curl python3 procps x11vnc xvfb dbus iproute2 screen \
                psmisc libxcursor1 libnss3 libfontconfig1 libxi6 libxss1 libxtst6 libegl-mesa0 libxcb-cursor0 \
                libegl1 libasound2t64 libglib2.0-0t64 libxcomposite-dev less jq libevent-2.1-7t64 \
                libxcb-xinerama0 liblcms2-2 libatomic1 libxcb-icccm4 libxcb-keysyms1 libxcb-randr0 \
                libxcb-render-util0 libxcb-shape0 libxcb-xkb1 libxkbcommon0 libxkbcommon-x11-0 libpci3 \
                libxslt1.1 libxcb-image0 x11-xkb-utils; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*
