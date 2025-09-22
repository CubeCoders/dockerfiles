# SinusBot dependencies image for AMP containers
# cubecoders/ampbase:sinusbot

FROM        cubecoders/ampbase:debian

LABEL       org.opencontainers.image.licenses=MIT

ENV         DEBIAN_FRONTEND="noninteractive"

# Install required packages
RUN         set -eux; \
            apt-get update; \
            # Purge PulseAudio libs from base image
            apt-get purge --auto-remove -y libpulse0 libpulse-mainloop-glib0; \
            \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                ca-certificates bzip2 unzip curl python3 procps x11vnc xvfb libxcursor1 libnss3 \
                libegl1 libasound2t64 libglib2.0-0t64 libxcomposite-dev less jq libevent-2.1-7t64 \
                libxcb-xinerama0 liblcms2-2 libatomic1 libxcb-icccm4 libxcb-keysyms1 libxcb-randr0 \
                libxcb-render-util0 libxcb-shape0 libxcb-xkb1 libxkbcommon0 libxkbcommon-x11-0 libpci3 \
                libxslt1.1 libxcb-image0; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*