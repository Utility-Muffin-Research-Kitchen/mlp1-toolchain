#!/usr/bin/env bash
set -euo pipefail

binary="${1:-examples/smoke/build/mlp1-smoke}"
readelf_bin="${READELF:-aarch64-buildroot-linux-gnu-readelf}"

if [ ! -f "$binary" ]; then
    echo "missing binary: $binary" >&2
    exit 1
fi

interp="$("$readelf_bin" -l "$binary" | awk '/Requesting program interpreter/ {gsub(/[\[\]]/, "", $NF); print $NF}')"
if [ "$interp" != "/lib/ld-linux-aarch64.so.1" ]; then
    echo "unexpected interpreter: ${interp:-missing}" >&2
    exit 1
fi

max_glibc="$("$readelf_bin" --version-info "$binary" 2>/dev/null | awk '
    match($0, /GLIBC_[0-9]+\.[0-9]+/) {
        v = substr($0, RSTART + 6, RLENGTH - 6);
        print v;
    }' | sort -V | tail -n 1)"

if [ -n "${max_glibc:-}" ]; then
    newest="$(printf '%s\n%s\n' "$max_glibc" "2.38" | sort -V | tail -n 1)"
    if [ "$newest" != "2.38" ]; then
        echo "binary requires GLIBC_$max_glibc, newer than target GLIBC_2.38" >&2
        exit 1
    fi
fi

echo "interpreter=$interp"
echo "max_glibc=${max_glibc:-none}"
echo "needed_libraries:"
"$readelf_bin" -d "$binary" | awk '/Shared library/ {gsub(/[\[\]]/, "", $NF); print "  " $NF}'

