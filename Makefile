# 便捷封装：真正的构建规则由 CMake 生成（build/ 目录下的 Makefile）。
# 这里只是把常用命令包一层，方便直接敲 `make`。
#
# 前提：cmake 已在 PATH 中；使用单配置生成器（MinGW Makefiles / Ninja / Unix Makefiles）。
#
#     make            配置 + 构建（Release）
#     make debug      配置 + 构建（Debug）
#     make run        构建后运行
#     make rebuild    清理后重新构建
#     make clean      删除 build/ 目录
#
# 注意：MSVC 多配置生成器会把产物放在 build/bin/<Config>/，
#       此封装脚本默认只适用于单配置生成器。

BUILD_DIR  ?= build
BUILD_TYPE ?= Release
JOBS       ?= 8
TARGET     ?= miniSoftwareRenderer

ifeq ($(OS),Windows_NT)
EXE := .exe
else
EXE :=
endif

BIN := $(BUILD_DIR)/bin/$(TARGET)$(EXE)

.PHONY: all configure build debug run clean rebuild

all: build

configure:
	cmake -S . -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=$(BUILD_TYPE)

build: configure
	cmake --build $(BUILD_DIR) --parallel $(JOBS)

debug:
	$(MAKE) build BUILD_TYPE=Debug

run: build
	$(BIN)

clean:
	cmake -E remove_directory $(BUILD_DIR)

rebuild: clean build
