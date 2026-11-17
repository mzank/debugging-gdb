# Debugging examples with GDB, CUDA-GDB, and ROCgdb

This repository contains small, self-contained examples for debugging CPU and
GPU programs with GDB, CUDA-GDB, and ROCgdb. Each debugger directory contains a
walkthrough, a cheat sheet, command files, and a script that builds the examples
and starts the corresponding debugger.

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

---

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

You can also view the license here: https://www.apache.org/licenses/LICENSE-2.0

---