#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILDROOT_VERSION="${BUILDROOT_VERSION:-2024.02}"
SDK_ARCH="${SDK_ARCH:-$("$ROOT_DIR/scripts/host-arch.sh")}"
SDK_CONFIG_ONLY="${SDK_CONFIG_ONLY:-0}"
HOST_UID="${HOST_UID:-$(id -u)}"
HOST_GID="${HOST_GID:-$(id -g)}"
SDK_BUILD_IMAGE="${SDK_BUILD_IMAGE:-ubuntu:24.04}"
SDK_DOCKER_WORKDIR="${SDK_DOCKER_WORKDIR:-volume}"
SDK_DOCKER_VOLUME="${SDK_DOCKER_VOLUME:-mlp1-toolchain-sdk-${SDK_ARCH}}"

case "$SDK_DOCKER_WORKDIR" in
    bind | volume)
        ;;
    *)
        echo "SDK_DOCKER_WORKDIR must be 'volume' or 'bind'." >&2
        exit 2
        ;;
esac

run_bind_workspace() {
    mkdir -p "$ROOT_DIR/.cache" "$ROOT_DIR/build" "$ROOT_DIR/dist"

    docker run --rm --platform "linux/$SDK_ARCH" \
        -e BUILDROOT_VERSION="$BUILDROOT_VERSION" \
        -e SDK_ARCH="$SDK_ARCH" \
        -e SDK_CONFIG_ONLY="$SDK_CONFIG_ONLY" \
        -e FORCE_UNSAFE_CONFIGURE=1 \
        -e HOST_UID="$HOST_UID" \
        -e HOST_GID="$HOST_GID" \
        -v "$ROOT_DIR":/workspace \
        -w /workspace \
        "$SDK_BUILD_IMAGE" \
        bash -lc './scripts/install-buildroot-deps.sh && ./scripts/build-sdk.sh && chown -R "$HOST_UID:$HOST_GID" .cache build dist'
}

run_volume_workspace() {
    mkdir -p "$ROOT_DIR/dist"
    docker volume create "$SDK_DOCKER_VOLUME" >/dev/null

    docker run --rm --platform "linux/$SDK_ARCH" \
        -e BUILDROOT_VERSION="$BUILDROOT_VERSION" \
        -e SDK_ARCH="$SDK_ARCH" \
        -e SDK_CONFIG_ONLY="$SDK_CONFIG_ONLY" \
        -e FORCE_UNSAFE_CONFIGURE=1 \
        -e HOST_UID="$HOST_UID" \
        -e HOST_GID="$HOST_GID" \
        -v "$ROOT_DIR":/host:ro \
        -v "$ROOT_DIR/dist":/host-dist \
        -v "$SDK_DOCKER_VOLUME":/workspace \
        -w /workspace \
        "$SDK_BUILD_IMAGE" \
        bash -lc '
            set -euo pipefail

            find /workspace -mindepth 1 -maxdepth 1 \
                ! -name .cache \
                ! -name build \
                ! -name dist \
                -exec rm -rf {} +
            tar -C /host \
                --exclude=.git \
                --exclude=.cache \
                --exclude=build \
                --exclude=dist \
                --exclude=workspace \
                --exclude=examples/smoke/build \
                -cf - . | tar -C /workspace -xf -

            ./scripts/install-buildroot-deps.sh
            ./scripts/build-sdk.sh

            if [ "${SDK_CONFIG_ONLY:-0}" != "1" ]; then
                cp -f \
                    "dist/mlp1-sdk-linux-${SDK_ARCH}.tar.gz" \
                    "dist/mlp1-sdk-linux-${SDK_ARCH}.txt" \
                    /host-dist/
                chown \
                    "${HOST_UID}:${HOST_GID}" \
                    "/host-dist/mlp1-sdk-linux-${SDK_ARCH}.tar.gz" \
                    "/host-dist/mlp1-sdk-linux-${SDK_ARCH}.txt"
            fi
        '
}

if [ "$SDK_DOCKER_WORKDIR" = "bind" ]; then
    run_bind_workspace
else
    run_volume_workspace
fi
