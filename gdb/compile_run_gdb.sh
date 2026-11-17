#!/bin/bash

set -e
export LC_ALL=C

SRC_DIR="../src"
BUILD_DIR="build"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# build
gcc -std=c2x -g -O0 -o "$BUILD_DIR/examplesegfault" "$SRC_DIR/examplesegfault.c"

# gdb
gdb -x commands_gdb_examplesegfault.txt ./build/examplesegfault > build/output_examplesegfault.txt 2>&1
