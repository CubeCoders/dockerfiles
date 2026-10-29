# syntax=docker/dockerfile:1

ARG         AMPBASE="cubecoders/amp3base:ubuntu"
FROM        ${AMPBASE}

LABEL       org.opencontainers.image.source="https://github.com/CubeCoders/dockerfiles"
LABEL       org.opencontainers.image.licenses="MIT"
LABEL       org.opencontainers.image.title="AMPBase v3 (Redis build dependencies)"
LABEL       org.opencontainers.image.description="AMPBase v3 plus what is needed to build Redis and its modules from source. Contains no AMP code."

ENV         DEBIAN_FRONTEND="noninteractive"

# Redis build dependencies plus a Rust toolchain, exposed as /opt/rust-bin without rustup.
RUN         set -eux; \
            export CARGO_HOME="/usr/local/cargo" RUSTUP_HOME="/usr/local/rustup"; \
            apt-get update; \
            apt-get install -o APT::Keep-Downloaded-Packages="false" -y --no-install-recommends \
                ca-certificates wget dpkg-dev gcc g++ libc6-dev libssl-dev make git cmake python3 \
                python3-pip python3-venv python3-dev python-is-python3 unzip rsync clang automake autoconf libtool pkg-config; \
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
            | sh -s -- -y --no-modify-path --profile minimal --default-toolchain stable; \
            /usr/local/cargo/bin/rustup default stable; \
            TOOLCHAIN="$(/usr/local/cargo/bin/rustup show active-toolchain | awk '{print $1}')"; \
            ln -s "/usr/local/rustup/toolchains/${TOOLCHAIN}/bin" /opt/rust-bin; \
            rm -f /usr/local/cargo/bin/cargo /usr/local/cargo/bin/rustc /usr/local/cargo/bin/rustdoc; \
            apt-get clean; \
            rm -rf /var/lib/apt/lists/*

# CARGO_HOME under the mounted HOME so the crate cache persists.
ENV         CARGO_HOME="/home/amp/.cargo"
ENV         AMP_EXTRA_PATH="/opt/rust-bin"
ENV         AMP_ADDITIONAL_ENV_VARS="CARGO_HOME"
