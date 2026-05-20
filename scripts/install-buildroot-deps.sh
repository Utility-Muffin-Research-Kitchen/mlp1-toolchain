#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/apt-install-retry.sh" \
    bc \
    bison \
    build-essential \
    ca-certificates \
    cpio \
    curl \
    file \
    flex \
    git \
    libncurses-dev \
    locales \
    make \
    patch \
    perl \
    python3 \
    rsync \
    unzip \
    wget \
    xz-utils
