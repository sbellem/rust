# Rust toolchain with xous target built from source
#
# This image is published to ghcr.io/betrusted-io/rust-xous-toolchain
# and used by xous-core CI for reproducible builds.

ARG RUST_VERSION="1.92.0"
FROM rust:${RUST_VERSION}-slim-bullseye AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        ca-certificates \
        build-essential \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install RISC-V GNU toolchain
RUN set -eux; \
    curl -fsSL https://github.com/xpack-dev-tools/riscv-none-embed-gcc-xpack/releases/download/v10.2.0-1.2/xpack-riscv-none-embed-gcc-10.2.0-1.2-linux-x64.tar.gz \
    | tar -xzf - -C /opt; \
    ln -s /opt/xpack-riscv-none-embed-gcc-10.2.0-1.2 /opt/riscv-gcc

ENV PATH="/opt/riscv-gcc/bin:${PATH}" \
    CC=riscv-none-embed-gcc \
    AR=riscv-none-embed-ar

RUN rustup target add riscv32imac-unknown-none-elf

WORKDIR /build
COPY . .

RUN ./rebuild.sh


FROM rust:${RUST_VERSION}-slim-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN rustup target add riscv32imac-unknown-none-elf

ARG RUST_VERSION
COPY --from=builder /usr/local/rustup/toolchains/${RUST_VERSION}-x86_64-unknown-linux-gnu/lib/rustlib/riscv32imac-unknown-xous-elf \
    /usr/local/rustup/toolchains/${RUST_VERSION}-x86_64-unknown-linux-gnu/lib/rustlib/riscv32imac-unknown-xous-elf

# Create non-root user for builds
RUN useradd --create-home --uid 1000 builder
USER builder
WORKDIR /home/builder/src
