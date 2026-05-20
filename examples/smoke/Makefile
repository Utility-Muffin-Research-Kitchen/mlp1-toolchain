CC ?= aarch64-buildroot-linux-gnu-gcc
PKG_CONFIG ?= pkg-config
BUILD_DIR ?= build
TARGET ?= $(BUILD_DIR)/mlp1-smoke

CFLAGS ?= -std=gnu11 -O2 -Wall -Wextra -Wno-unused-parameter
SDL_CFLAGS := $(shell $(PKG_CONFIG) --cflags sdl2 SDL2_ttf SDL2_image)
SDL_LDLIBS := $(shell $(PKG_CONFIG) --libs sdl2 SDL2_ttf SDL2_image)

.PHONY: all clean

all: $(TARGET)

$(TARGET): main.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(SDL_CFLAGS) -o $@ $< $(SDL_LDLIBS)

clean:
	rm -rf $(BUILD_DIR)

