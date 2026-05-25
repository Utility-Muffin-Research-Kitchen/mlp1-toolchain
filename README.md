# MLP1 Toolchain

Buildroot-based cross-compilation image for the Miniloong Pocket 1.

The published image is intentionally public and blob-free. It builds an
aarch64/Cortex-A55 SDK from Buildroot 2024.02 with GCC 12.3.0, glibc 2.38,
Linux 5.10.x headers, and the first-pass UMRK runtime library surface:
SDL2, SDL2_image, SDL2_ttf, freetype, harfbuzz, libpng, jpeg, zlib, sqlite,
alsa-lib, libdrm, and standard EGL/GLES interfaces.

It does not copy or redistribute stock Miniloong firmware libraries, Mali
drivers, or other device blobs.

## Device Baseline

The initial target was probed over ADB as:

```text
Linux rk3566-buildroot 5.10.209 aarch64
Buildroot 2021.11
glibc 2.38
GCC runtime 12.3.0 era, libstdc++.so.6.0.30
Rockchip RK3566 / Cortex-A55
```

`/mnt/sdcard` is mounted `noexec` on the stock firmware, so smoke-test
binaries are deployed to `/tmp`.

## Image Interface

The container exports:

```text
CROSS_TRIPLE=aarch64-buildroot-linux-gnu
CROSS_COMPILE=aarch64-buildroot-linux-gnu-
TOOLCHAIN_DIR=/opt/mlp1-toolchain
SYSROOT=/opt/mlp1-toolchain/aarch64-buildroot-linux-gnu/sysroot
CC=/opt/mlp1-toolchain/bin/aarch64-buildroot-linux-gnu-gcc
CXX=/opt/mlp1-toolchain/bin/aarch64-buildroot-linux-gnu-g++
AR=/opt/mlp1-toolchain/bin/aarch64-buildroot-linux-gnu-ar
LD=/opt/mlp1-toolchain/bin/aarch64-buildroot-linux-gnu-ld
CMAKE_TOOLCHAIN_FILE=/opt/mlp1-toolchain/Toolchain.cmake
PKG_CONFIG_SYSROOT_DIR=/opt/mlp1-toolchain/aarch64-buildroot-linux-gnu/sysroot
UNION_PLATFORM=mlp1
```

Published image:

```sh
docker pull ghcr.io/utility-muffin-research-kitchen/mlp1-toolchain:latest
```

## Local Commands

Build the SDK tarball for the current Docker host architecture:

```sh
make sdk
```

Local SDK builds default to a persistent Docker volume workspace so Buildroot
does not build its large tree on a macOS shared mount. To force the old
host-bind workspace mode:

```sh
SDK_DOCKER_WORKDIR=bind make sdk
```

Remove the persistent SDK workspace volume:

```sh
make clean-sdk-volume
```

Build the local container image:

```sh
make image
```

Open a shell in the toolchain container:

```sh
make shell
```

Build the target smoke binary:

```sh
make smoke
```

Build, validate, push to `/tmp`, and run the smoke binary on the connected
MLP1 over ADB:

```sh
make smoke-adb
```

## Smoke Test

`examples/smoke/` is deliberately small. It initializes SDL2, SDL2_ttf, and
SDL2_image, prints the active SDL video driver, opens a window, optionally
loads paths from `MLP1_SMOKE_FONT` and `MLP1_SMOKE_IMAGE`, renders a few
frames, and exits.

The ADB wrapper checks:

- the connected device looks like an RK3566 aarch64 Buildroot MLP1;
- glibc reports version 2.38;
- the target interpreter is `/lib/ld-linux-aarch64.so.1`;
- every `NEEDED` library is present under `/lib` or `/usr/lib` on the device;
- the binary runs from `/tmp/umrk-mlp1-smoke/`.

## CI

- `.github/workflows/build-sdk.yml` builds `linux/amd64` and `linux/arm64`
  SDK artifacts.
- `.github/workflows/docker-build.yml` builds SDK artifacts, then publishes
  a multi-platform GHCR image from those artifacts.
