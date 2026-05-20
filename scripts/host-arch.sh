#!/usr/bin/env bash
set -euo pipefail

arch="$(uname -m)"
case "$arch" in
    x86_64|amd64)
        echo amd64
        ;;
    arm64|aarch64)
        echo arm64
        ;;
    *)
        echo "unsupported host architecture: $arch" >&2
        exit 1
        ;;
esac

