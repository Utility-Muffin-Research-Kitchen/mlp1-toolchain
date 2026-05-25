SHELL := /bin/bash

TOOLCHAIN_NAME := mlp1-toolchain
IMAGE_REPO ?= ghcr.io/utility-muffin-research-kitchen
IMAGE_NAME ?= $(IMAGE_REPO)/$(TOOLCHAIN_NAME)
IMAGE_TAG ?= local
LOCAL_IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)

BUILDROOT_VERSION ?= 2024.02
SDK_ARCH ?= $(shell scripts/host-arch.sh)
HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)
WORKSPACE_DIR := $(CURDIR)/workspace
SDK_BUILD_IMAGE ?= ubuntu:24.04
SDK_DOCKER_WORKDIR ?= volume
SDK_DOCKER_VOLUME ?= $(TOOLCHAIN_NAME)-sdk-$(SDK_ARCH)

.PHONY: sdk sdk-config image shell smoke smoke-adb clean clean-sdk-volume help

sdk:
	BUILDROOT_VERSION=$(BUILDROOT_VERSION) \
		SDK_ARCH=$(SDK_ARCH) \
		HOST_UID=$(HOST_UID) \
		HOST_GID=$(HOST_GID) \
		SDK_BUILD_IMAGE=$(SDK_BUILD_IMAGE) \
		SDK_DOCKER_WORKDIR=$(SDK_DOCKER_WORKDIR) \
		SDK_DOCKER_VOLUME=$(SDK_DOCKER_VOLUME) \
		./scripts/build-sdk-in-docker.sh

sdk-config:
	BUILDROOT_VERSION=$(BUILDROOT_VERSION) \
		SDK_ARCH=$(SDK_ARCH) \
		SDK_CONFIG_ONLY=1 \
		HOST_UID=$(HOST_UID) \
		HOST_GID=$(HOST_GID) \
		SDK_BUILD_IMAGE=$(SDK_BUILD_IMAGE) \
		SDK_DOCKER_WORKDIR=$(SDK_DOCKER_WORKDIR) \
		SDK_DOCKER_VOLUME=$(SDK_DOCKER_VOLUME) \
		./scripts/build-sdk-in-docker.sh

image: sdk
	docker build \
		--build-arg SDK_DIR=dist \
		-t $(LOCAL_IMAGE) \
		.

shell: image
	@mkdir -p "$(WORKSPACE_DIR)"
	docker run -it --rm \
		-v "$(WORKSPACE_DIR)":/root/workspace \
		-v "$(CURDIR)":/workspace \
		-w /root/workspace \
		$(LOCAL_IMAGE) \
		/bin/bash

smoke: image
	docker run --rm \
		-v "$(CURDIR)":/workspace \
		-w /workspace \
		$(LOCAL_IMAGE) \
		make -C examples/smoke clean all

smoke-adb: image
	IMAGE_NAME=$(LOCAL_IMAGE) ./scripts/adb-smoke.sh

clean:
	rm -rf build dist .build examples/smoke/build

clean-sdk-volume:
	docker volume rm "$(SDK_DOCKER_VOLUME)" || true

help:
	@echo "MLP1 toolchain targets"
	@echo ""
	@echo "  make sdk        Build Buildroot SDK tarball for linux/$(SDK_ARCH)"
	@echo "  make sdk-config Validate the Buildroot SDK defconfig only"
	@echo "  make image      Build local Docker image $(LOCAL_IMAGE)"
	@echo "  make shell      Open a shell in the local toolchain image"
	@echo "  make smoke      Build the target SDL smoke binary"
	@echo "  make smoke-adb  Build, validate, push, and run smoke binary over ADB"
	@echo "  make clean      Remove generated outputs"
	@echo "  make clean-sdk-volume"
	@echo "                  Remove persistent Docker SDK workspace volume $(SDK_DOCKER_VOLUME)"
