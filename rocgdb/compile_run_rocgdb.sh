#!/bin/bash

set -e
export LC_ALL=C

SRC_DIR="../src"
BUILD_DIR="build"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# build
amdclang++ -std=c++20 -ggdb -O0 -x hip --offload-arch=gfx942 -o "$BUILD_DIR/vectoradd" "$SRC_DIR/vectoradd.hip"

amdclang++ -std=c++20 -ggdb -O0 -fopenmp --offload-arch=gfx942 -o "$BUILD_DIR/vectoraddomp" "$SRC_DIR/vectoraddomp.cpp"

# rocgdb
rocgdb -x commands_rocgdb_vectoradd.txt ./build/vectoradd > build/output_vectoradd.txt 2>&1

rocgdb -x commands_rocgdb_vectoraddomp.txt ./build/vectoraddomp > build/output_vectoraddomp.txt 2>&1
