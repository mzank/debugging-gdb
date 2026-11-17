#!/bin/bash

set -e
export LC_ALL=C

SRC_DIR="../src"
BUILD_DIR="build"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# build
nvcc -std=c++20 -g -G -O0 -o "$BUILD_DIR/vectoradd" "$SRC_DIR/vectoradd.cu"

nvc++ -std=c++20 -g -O0 -acc -gpu=debug -Minfo=accel -o "$BUILD_DIR/vectoraddacc" "$SRC_DIR/vectoraddacc.cpp"

nvc++ -std=c++20 -g -O0 -mp=gpu -gpu=debug -Minfo=mp -o "$BUILD_DIR/vectoraddomp" "$SRC_DIR/vectoraddomp.cpp"

# cuda-gdb
cuda-gdb -x commands_cuda-gdb_vectoradd.txt ./build/vectoradd > build/output_vectoradd.txt 2>&1

cuda-gdb -x commands_cuda-gdb_vectoraddacc_omp.txt ./build/vectoraddacc > build/output_vectoraddacc.txt 2>&1

cuda-gdb -x commands_cuda-gdb_vectoraddacc_omp.txt ./build/vectoraddomp > build/output_vectoraddomp.txt 2>&1
