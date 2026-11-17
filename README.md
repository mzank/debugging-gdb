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

---

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

You can also view the license here: https://www.apache.org/licenses/LICENSE-2.0

---