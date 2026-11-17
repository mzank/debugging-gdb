# Debugging examples with GDB, CUDA-GDB, and ROCgdb

This repository contains small, self-contained examples for debugging CPU and
GPU programs with GDB, CUDA-GDB, and ROCgdb. Each debugger directory contains a
walkthrough, a cheat sheet, command files, and a script that builds the examples
and starts the corresponding debugger.

## Table of contents

- [Repository layout](#repository-layout)
- [Debugger coverage](#debugger-coverage)
- [Example programs](#example-programs)
- [Quick start](#quick-start)
- [Prerequisites](#prerequisites)
- [Example walkthroughs](#example-walkthroughs)
- [Captured output](#captured-output)
- [License](#license)

## Repository layout

| Path | Contents |
| --- | --- |
| [`src/`](src/) | Example programs |
| [`gdb/`](gdb/) | GDB walkthrough, cheat sheet, command file, and build/run script |
| [`cuda-gdb/`](cuda-gdb/) | CUDA-GDB walkthroughs for CUDA, OpenACC, and OpenMP, plus cheat sheet, command files, and build/run script |
| [`rocgdb/`](rocgdb/) | ROCgdb walkthroughs for HIP and OpenMP, plus cheat sheet, command files, and build/run script |

Each debugger directory also has an `output/` directory with captured session
transcripts.

## Debugger coverage

| Directory | Debugger | Examples | Walkthrough | Cheat sheet |
| --- | --- | --- | --- | --- |
| [`gdb/`](gdb/) | GNU Debugger (GDB) | Segmentation fault | [`gdb/README.md`](gdb/README.md) | [`gdb_cheat_sheet.md`](gdb/gdb_cheat_sheet.md) |
| [`cuda-gdb/`](cuda-gdb/) | NVIDIA CUDA-GDB | CUDA, OpenACC, OpenMP | [`cuda-gdb/README.md`](cuda-gdb/README.md) | [`cuda-gdb_cheat_sheet.md`](cuda-gdb/cuda-gdb_cheat_sheet.md) |
| [`rocgdb/`](rocgdb/) | AMD ROCgdb | HIP, OpenMP | [`rocgdb/README.md`](rocgdb/README.md) | [`rocgdb_cheat_sheet.md`](rocgdb/rocgdb_cheat_sheet.md) |

## Example programs

The examples cover a segmentation fault in a C23 program and C++20 programs
using CUDA, HIP, OpenACC, and OpenMP.

| File | Language / model | Example | Debugger |
| --- | --- | --- | --- |
| [`examplesegfault.c`](src/examplesegfault.c) | C23 | Segmentation fault | [GDB](gdb/README.md) |
| [`vectoradd.cu`](src/vectoradd.cu) | C++20 / CUDA | CUDA kernels | [CUDA-GDB](cuda-gdb/README.md) |
| [`vectoradd.hip`](src/vectoradd.hip) | C++20 / HIP | HIP kernels | [ROCgdb](rocgdb/README.md) |
| [`vectoraddacc.cpp`](src/vectoraddacc.cpp) | C++20 / OpenACC | OpenACC offloading | [CUDA-GDB](cuda-gdb/README.md) |
| [`vectoraddomp.cpp`](src/vectoraddomp.cpp) | C++20 / OpenMP | OpenMP offloading | [CUDA-GDB](cuda-gdb/README.md) and [ROCgdb](rocgdb/README.md) |

## Quick start

From the repository root, run:

```bash
(cd gdb && ./compile_run_gdb.sh)
(cd cuda-gdb && ./compile_run_cuda-gdb.sh)
(cd rocgdb && ./compile_run_rocgdb.sh)
```

The scripts must run from their own debugger directory because they use paths
relative to that directory, including `../src`. Each script:

- Deletes and recreates the debugger directory's `build/` directory.
- Builds the relevant example programs into `build/`.
- Runs the debugger with its command files and writes the session transcript to
  `build/output_*.txt`.

See each debugger directory's README for the exact build commands and debugging
sessions.

## Prerequisites

- **GDB example:** a C compiler with C23 support, such as `gcc` (the script
  uses `-std=c2x`), and GDB.
- **CUDA-GDB examples:** the NVIDIA CUDA toolkit and an NVIDIA GPU. The CUDA
  example uses `nvcc`; the OpenACC and OpenMP examples use `nvc++` with GPU
  offloading enabled.
- **ROCgdb examples:** ROCm, an AMD GPU, `amdclang++`, and ROCgdb.

The ROCgdb script builds for `gfx942` with `--offload-arch=gfx942`, as used on
an AMD Instinct MI300A. Adjust this flag for other AMD GPUs; see the
[LLVM AMDGPU usage documentation](https://llvm.org/docs/AMDGPUUsage.html) for
the correct `gfx` target name.

## Example walkthroughs

### Segmentation fault (GDB)

`src/examplesegfault.c` dereferences a null pointer on its second call to
`calculate()`. The GDB walkthrough uses breakpoints, `backtrace`, reverse
debugging, and variable inspection to find the fault and test a fix.

### CUDA kernels (CUDA-GDB)

`src/vectoradd.cu` adds two vectors with two CUDA kernels: one thread per
element and a grid-stride loop. The CUDA-GDB walkthrough inspects kernels,
blocks, threads, warps, and lanes, and follows selected CUDA threads while
stepping at warp granularity.

### HIP kernels (ROCgdb)

`src/vectoradd.hip` is the HIP counterpart of the CUDA example. The ROCgdb
walkthrough introduces wavefronts and lanes and shows how to select work-items
within a wavefront while stepping at wavefront granularity.

### OpenACC offloading (CUDA-GDB)

`src/vectoraddacc.cpp` uses `#pragma acc parallel loop` to offload vector
addition to the GPU. The CUDA-GDB walkthrough inspects the generated CUDA
kernel and its threads, warps, and lanes.

### OpenMP offloading (CUDA-GDB and ROCgdb)

`src/vectoraddomp.cpp` uses `#pragma omp target teams distribute parallel for`
to offload the vector addition across 1024 CUDA threads or work-items, with one
loop iteration per thread or work-item. The CUDA-GDB and ROCgdb walkthroughs
inspect the generated kernel and the state of its active, inactive, or divergent
lanes.

## Captured output

The files in [`gdb/output/`](gdb/output/),
[`cuda-gdb/output/`](cuda-gdb/output/), and [`rocgdb/output/`](rocgdb/output/)
are captured reference transcripts from the included sessions. They are not
updated automatically by the scripts. Addresses, debugger-specific thread,
warp, wavefront, and lane IDs, scheduling, and generated kernel names can vary
with the compiler, driver, debugger version, and GPU, so treat the captured
output as a guide rather than an exact expected result.

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

You can also view the license here: https://www.apache.org/licenses/LICENSE-2.0