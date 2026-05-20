#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
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

rm -rf /var/lib/apt/lists/*

