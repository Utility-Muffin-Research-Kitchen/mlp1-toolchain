FROM docker.io/library/ubuntu:24.04

ARG TARGETARCH
ARG SDK_DIR=dist

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    cmake \
    file \
    git \
    make \
    ninja-build \
    pkg-config \
    python3 \
    rsync \
    unzip \
    vim \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

ENV TOOLCHAIN_DIR=/opt/mlp1-toolchain
COPY ${SDK_DIR}/mlp1-sdk-linux-${TARGETARCH}.tar.gz /tmp/mlp1-sdk.tar.gz

RUN mkdir -p "${TOOLCHAIN_DIR}" \
    && tar -xzf /tmp/mlp1-sdk.tar.gz -C "${TOOLCHAIN_DIR}" \
    && rm -f /tmp/mlp1-sdk.tar.gz \
    && if [ -x "${TOOLCHAIN_DIR}/relocate-sdk.sh" ]; then \
        "${TOOLCHAIN_DIR}/relocate-sdk.sh"; \
    fi

ENV CROSS_TRIPLE=aarch64-buildroot-linux-gnu
ENV CROSS_ROOT=${TOOLCHAIN_DIR}
ENV SYSROOT=${TOOLCHAIN_DIR}/${CROSS_TRIPLE}/sysroot

ENV AS=${TOOLCHAIN_DIR}/bin/${CROSS_TRIPLE}-as \
    AR=${TOOLCHAIN_DIR}/bin/${CROSS_TRIPLE}-ar \
    CC=${TOOLCHAIN_DIR}/bin/${CROSS_TRIPLE}-gcc \
    CPP=${TOOLCHAIN_DIR}/bin/${CROSS_TRIPLE}-cpp \
    CXX=${TOOLCHAIN_DIR}/bin/${CROSS_TRIPLE}-g++ \
    LD=${TOOLCHAIN_DIR}/bin/${CROSS_TRIPLE}-ld \
    STRIP=${TOOLCHAIN_DIR}/bin/${CROSS_TRIPLE}-strip \
    READELF=${TOOLCHAIN_DIR}/bin/${CROSS_TRIPLE}-readelf

ENV PATH=${TOOLCHAIN_DIR}/bin:${PATH}
ENV CROSS_COMPILE=${CROSS_TRIPLE}-
ENV PREFIX=${SYSROOT}/usr
ENV ARCH=aarch64
ENV PKG_CONFIG_SYSROOT_DIR=${SYSROOT}
ENV PKG_CONFIG_PATH=${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig
ENV CMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_DIR}/Toolchain.cmake
ENV UNION_PLATFORM=mlp1
ENV PREFIX_LOCAL=/opt/umrk

COPY toolchain-aarch64.cmake ${TOOLCHAIN_DIR}/Toolchain.cmake

RUN mkdir -p "${PREFIX_LOCAL}/include" "${PREFIX_LOCAL}/lib"

VOLUME /root/workspace
WORKDIR /root/workspace

