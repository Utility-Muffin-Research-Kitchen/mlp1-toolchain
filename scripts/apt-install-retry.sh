#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
    echo "usage: $0 <apt-package>..." >&2
    exit 2
fi

export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"

attempts="${APT_INSTALL_ATTEMPTS:-4}"
delay="${APT_INSTALL_RETRY_DELAY:-15}"
apt_opts=(
    -o Acquire::Retries=5
)

for attempt in $(seq 1 "$attempts"); do
    echo "Installing apt packages, attempt ${attempt}/${attempts}: $*"
    rm -rf /var/lib/apt/lists/*

    if apt-get "${apt_opts[@]}" update \
        && apt-get "${apt_opts[@]}" install -y --no-install-recommends "$@"; then
        rm -rf /var/lib/apt/lists/*
        exit 0
    else
        status=$?
    fi

    if [ "$attempt" -eq "$attempts" ]; then
        echo "apt package installation failed after ${attempts} attempts." >&2
        exit "$status"
    fi

    echo "apt package installation failed; retrying in ${delay}s." >&2
    sleep "$delay"
done
