#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILDROOT_VERSION="${BUILDROOT_VERSION:-2024.02}"
SDK_ARCH="${SDK_ARCH:-$("$ROOT_DIR/scripts/host-arch.sh")}"

CACHE_DIR="${CACHE_DIR:-$ROOT_DIR/.cache}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
BR_TARBALL="$CACHE_DIR/buildroot-${BUILDROOT_VERSION}.tar.xz"
BR_URL="https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.xz"
BR_SRC="$BUILD_DIR/buildroot-${BUILDROOT_VERSION}"
BR_OUT="$BUILD_DIR/buildroot-output-${SDK_ARCH}"
SDK_TAR="$DIST_DIR/mlp1-sdk-linux-${SDK_ARCH}.tar.gz"

mkdir -p "$CACHE_DIR" "$BUILD_DIR" "$DIST_DIR"

if [ ! -f "$BR_TARBALL" ]; then
    echo "Downloading Buildroot ${BUILDROOT_VERSION}..."
    curl -fL "$BR_URL" -o "$BR_TARBALL"
fi

if [ ! -d "$BR_SRC" ]; then
    echo "Extracting Buildroot ${BUILDROOT_VERSION}..."
    mkdir -p "$BR_SRC"
    tar -xJf "$BR_TARBALL" -C "$BR_SRC" --strip-components=1
fi

echo "Configuring MLP1 SDK..."
make -C "$BR_SRC" \
    O="$BR_OUT" \
    BR2_EXTERNAL="$ROOT_DIR/br2-external" \
    mlp1_sdk_defconfig

make -C "$BR_SRC" O="$BR_OUT" olddefconfig

if [ "${SDK_CONFIG_ONLY:-0}" = "1" ]; then
    echo "SDK_CONFIG_ONLY=1; stopping after Buildroot configuration."
    exit 0
fi

echo "Building MLP1 SDK. This can take a while..."
make -C "$BR_SRC" O="$BR_OUT" sdk

host_dir="$BR_OUT/host"
if [ ! -x "$host_dir/bin/aarch64-buildroot-linux-gnu-gcc" ]; then
    echo "Buildroot host SDK is missing the expected cross compiler." >&2
    exit 1
fi

echo "Packaging normalized SDK: $SDK_TAR"
tmp_info="$BUILD_DIR/sdk-info-${SDK_ARCH}.txt"
{
    echo "buildroot_version=${BUILDROOT_VERSION}"
    echo "sdk_arch=${SDK_ARCH}"
    "$host_dir/bin/aarch64-buildroot-linux-gnu-gcc" --version | head -n 1
    "$host_dir/bin/aarch64-buildroot-linux-gnu-g++" --version | head -n 1
} > "$tmp_info"

tar -czf "$SDK_TAR" -C "$host_dir" .
cp -f "$tmp_info" "$DIST_DIR/mlp1-sdk-linux-${SDK_ARCH}.txt"

echo "Wrote $SDK_TAR"
