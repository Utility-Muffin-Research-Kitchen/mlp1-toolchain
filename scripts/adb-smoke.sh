#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/utility-muffin-research-kitchen/mlp1-toolchain:local}"
BINARY_REL="examples/smoke/build/mlp1-smoke"
BINARY="$ROOT_DIR/$BINARY_REL"
REMOTE_DIR="/tmp/umrk-mlp1-smoke"
REMOTE_BIN="$REMOTE_DIR/mlp1-smoke"

if [ "${SKIP_BUILD:-0}" != "1" ]; then
    make -C "$ROOT_DIR" smoke
fi

if [ -n "${ADB_SERIAL:-}" ]; then
    ADB=(adb -s "$ADB_SERIAL")
else
    serial="$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
    if [ -z "${serial:-}" ]; then
        echo "No online adb device found." >&2
        exit 1
    fi
    ADB=(adb -s "$serial")
fi

echo "Using adb device: $("${ADB[@]}" get-serialno)"

# shellcheck disable=SC2016
probe="$("${ADB[@]}" shell 'set -u
printf "UNAME_M=%s\n" "$(uname -m 2>/dev/null || true)"
printf "UNAME_A=%s\n" "$(uname -a 2>/dev/null || true)"
printf "OS_RELEASE_BEGIN\n"
cat /etc/os-release 2>/dev/null || true
printf "OS_RELEASE_END\n"
printf "LIBC_BEGIN\n"
/lib/libc.so.6 2>&1 | head -n 8 || true
printf "LIBC_END\n"
printf "DT_MODEL="
tr "\000" "\n" < /proc/device-tree/model 2>/dev/null || true
printf "\nDT_COMPATIBLE="
tr "\000" "\n" < /proc/device-tree/compatible 2>/dev/null || true
printf "\n"
' | tr -d '\r')"

printf '%s\n' "$probe"

printf '%s\n' "$probe" | grep -q 'UNAME_M=aarch64' || {
    echo "Device is not aarch64." >&2
    exit 1
}
printf '%s\n' "$probe" | grep -qi 'Buildroot' || {
    echo "Device does not look like Buildroot." >&2
    exit 1
}
printf '%s\n' "$probe" | grep -qi 'rk3566' || {
    echo "Device does not look like an RK3566 MLP1 target." >&2
    exit 1
}
printf '%s\n' "$probe" | grep -q 'GNU C Library.*2\.38\|stable release version 2\.38' || {
    echo "Device glibc is not 2.38." >&2
    exit 1
}

echo "Verifying target binary..."
docker run --rm \
    -v "$ROOT_DIR":/workspace \
    -w /workspace \
    "$IMAGE_NAME" \
    ./scripts/verify-binary.sh "$BINARY_REL"

needed="$(docker run --rm \
    -v "$ROOT_DIR":/workspace \
    -w /workspace \
    "$IMAGE_NAME" \
    bash -lc "aarch64-buildroot-linux-gnu-readelf -d '$BINARY_REL' | awk '/Shared library/ {gsub(/[\\[\\]]/, \"\", \\\$NF); print \\\$NF}'")"

echo "Checking NEEDED libraries on device..."
while IFS= read -r lib; do
    [ -n "$lib" ] || continue
    "${ADB[@]}" shell "test -e '/lib/$lib' -o -e '/usr/lib/$lib' -o -n \"\$(find /lib /usr/lib -maxdepth 2 -name '$lib' 2>/dev/null | head -n 1)\"" >/dev/null || {
        echo "Missing device library: $lib" >&2
        exit 1
    }
    echo "  ok $lib"
done <<< "$needed"

echo "Deploying smoke binary to $REMOTE_DIR..."
"${ADB[@]}" shell "rm -rf '$REMOTE_DIR' && mkdir -p '$REMOTE_DIR'"
"${ADB[@]}" push "$BINARY" "$REMOTE_BIN" >/dev/null
"${ADB[@]}" shell "chmod 755 '$REMOTE_BIN'"

echo "Running smoke binary from /tmp..."
"${ADB[@]}" shell "cd '$REMOTE_DIR' && SDL_VIDEODRIVER=\${SDL_VIDEODRIVER:-kmsdrm} '$REMOTE_BIN'"

echo "ADB smoke test completed."
