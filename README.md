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

---

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

You can also view the license here: https://www.apache.org/licenses/LICENSE-2.0

---