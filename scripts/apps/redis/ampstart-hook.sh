# Redis start hook (sourced by /ampstart.sh): Rust toolchain on PATH, per-user CARGO_HOME
CARGO_HOME="/home/amp/.cargo"
install -d -m 0755 -o amp -g amp "${CARGO_HOME}"
AMP_PATH="/opt/rust-bin:${AMP_PATH}"
AMP_ADDITIONAL_ENV_VARS="${AMP_ADDITIONAL_ENV_VARS-} CARGO_HOME"
