CC ?= aarch64-buildroot-linux-gnu-gcc
PKG_CONFIG ?= pkg-config
BUILD_DIR ?= build
TARGET ?= $(BUILD_DIR)/mlp1-smoke
MLP1_FLAGS_MK ?= $(firstword $(wildcard /opt/mlp1-toolchain/umrk/mlp1-build-flags.mk ../../flags/mlp1-build-flags.mk))
ifneq ($(MLP1_FLAGS_MK),)
include $(MLP1_FLAGS_MK)
else
UMRK_MLP1_PROFILE_CFLAGS ?= -O2 -mcpu=cortex-a55 -mtune=cortex-a55 -ffunction-sections -fdata-sections -DNDEBUG
endif

CFLAGS ?= -std=gnu11 $(UMRK_MLP1_PROFILE_CFLAGS) -Wall -Wextra -Wno-unused-parameter
SDL_CFLAGS := $(shell $(PKG_CONFIG) --cflags sdl2 SDL2_ttf SDL2_image)
SDL_LDLIBS := $(shell $(PKG_CONFIG) --libs sdl2 SDL2_ttf SDL2_image)

.PHONY: all clean

all: $(TARGET)

$(TARGET): main.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(SDL_CFLAGS) -o $@ $< $(SDL_LDLIBS)

clean:
	rm -rf $(BUILD_DIR)
