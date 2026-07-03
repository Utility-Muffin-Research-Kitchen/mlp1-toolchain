#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

flags_env=${UMRK_MLP1_FLAGS_ENV:-}
if [ -z "$flags_env" ]; then
    if [ -f /opt/mlp1-toolchain/umrk/mlp1-build-flags.env ]; then
        flags_env=/opt/mlp1-toolchain/umrk/mlp1-build-flags.env
    else
        flags_env=$repo_root/flags/mlp1-build-flags.env
    fi
fi

. "$flags_env"

format=${1:-shell}
case "$format" in
    shell)
        cat <<EOF
UMRK_MLP1_TARGET_SOC='$UMRK_MLP1_TARGET_SOC'
UMRK_MLP1_TARGET_CPU='$UMRK_MLP1_TARGET_CPU'
UMRK_MLP1_BUILD_PROFILE='$UMRK_MLP1_BUILD_PROFILE'
UMRK_MLP1_PROFILE_CFLAGS='$UMRK_MLP1_PROFILE_CFLAGS'
UMRK_MLP1_PROFILE_CXXFLAGS='$UMRK_MLP1_PROFILE_CXXFLAGS'
UMRK_MLP1_PROFILE_LDFLAGS='$UMRK_MLP1_PROFILE_LDFLAGS'
EOF
        ;;
    make)
        cat <<EOF
UMRK_MLP1_TARGET_SOC := $UMRK_MLP1_TARGET_SOC
UMRK_MLP1_TARGET_CPU := $UMRK_MLP1_TARGET_CPU
UMRK_MLP1_BUILD_PROFILE := $UMRK_MLP1_BUILD_PROFILE
UMRK_MLP1_PROFILE_CFLAGS := $UMRK_MLP1_PROFILE_CFLAGS
UMRK_MLP1_PROFILE_CXXFLAGS := $UMRK_MLP1_PROFILE_CXXFLAGS
UMRK_MLP1_PROFILE_LDFLAGS := $UMRK_MLP1_PROFILE_LDFLAGS
EOF
        ;;
    json)
        python3 - "$UMRK_MLP1_TARGET_SOC" "$UMRK_MLP1_TARGET_CPU" \
            "$UMRK_MLP1_BUILD_PROFILE" "$UMRK_MLP1_PROFILE_CFLAGS" \
            "$UMRK_MLP1_PROFILE_CXXFLAGS" "$UMRK_MLP1_PROFILE_LDFLAGS" <<'PY'
import json
import sys

keys = [
    "target_soc",
    "target_cpu",
    "build_profile",
    "cflags",
    "cxxflags",
    "ldflags",
]
print(json.dumps(dict(zip(keys, sys.argv[1:])), indent=2))
PY
        ;;
    *)
        echo "usage: $0 [shell|make|json]" >&2
        exit 64
        ;;
esac
