# CUDA-GDB: vector addition examples

See the [CUDA-GDB cheat sheet](cuda-gdb_cheat_sheet.md) for a reference of the
commands used here. The cheat sheet's
[Software and hardware views](cuda-gdb_cheat_sheet.md#5-software-and-hardware-views)
section explains how CUDA blocks, threads, SMs, warps, lanes, and CUDA cores
relate to the launch configurations and `info cuda` output in these examples.

## Table of contents

- [CUDA example: vectoradd](#cuda-example-vectoradd)
- [OpenACC example: vectoraddacc](#openacc-example-vectoraddacc)
- [OpenMP example: vectoraddomp](#openmp-example-vectoraddomp)
- [Compile and run](#compile-and-run)

## CUDA example: vectoradd

### Files

| File | Purpose |
| --- | --- |
| [`../src/vectoradd.cu`](../src/vectoradd.cu) | C++20 CUDA program for vector addition |
| [`commands_cuda-gdb_vectoradd.txt`](commands_cuda-gdb_vectoradd.txt) | CUDA-GDB command file for the debugging session |
| [`compile_run_cuda-gdb.sh`](compile_run_cuda-gdb.sh) | Builds the examples and runs CUDA-GDB with the command files |
| [`output/output_vectoradd.txt`](output/output_vectoradd.txt) | Captured CUDA-GDB output of the session |
| [`cuda-gdb_cheat_sheet.md`](cuda-gdb_cheat_sheet.md) | Cheat sheet for the CUDA-GDB commands used in this example |

### The example program

`../src/vectoradd.cu` is a C++20 CUDA program that adds two vectors on the GPU. It
uses `std::array`, `std::iota`, `std::ranges::transform`, `std::views::iota`,
and `std::format` on the host side.

The program uses `vec_size = 999` and prints the first `print_size = 10`
results. It initializes `h_A` with `0..998` and `h_B` with twice those values,
allocates the device arrays, and copies the inputs to the GPU.

The file defines two CUDA kernels:

- `vectorAdd` computes one element per CUDA thread:

  ```cpp
  unsigned int const i{blockIdx.x * blockDim.x + threadIdx.x};

  if (i < size)
  {
      C[i] = A[i] + B[i];
  }
  ```

  It is launched with 15 blocks of 67 threads, giving 1005 threads for 999
  elements.

- `vectorAddStride` uses a grid-stride loop:

  ```cpp
  unsigned int const tid{blockIdx.x * blockDim.x + threadIdx.x};
  unsigned int const stride{blockDim.x * gridDim.x};

  for (unsigned int i = tid; i < size; i += stride)
  {
      C[i] = A[i] + B[i];
  }
  ```

  It is launched with 5 blocks of 71 threads (355 threads), so each thread
  processes multiple elements.

Both kernels store their results in separate device arrays. The host copies
the results back and prints the first ten rows for each approach. The helper
`cudaCheck()` reports errors returned by CUDA API calls.

### The debugging session

`commands_cuda-gdb_vectoradd.txt` is run with `cuda-gdb -x`. It enables command
tracing with `set trace-commands on`, sets breakpoints at lines 35 and 51, and
then runs the program.

CUDA-GDB creates a breakpoint for both host and device code. Because lines 35
and 51 are inside device kernels, the captured output reports the host-side
breakpoint at the end of the enclosing block (lines 39 and 55), while execution
stops at the device lines 35 and 51.

The first breakpoint is inside `vectorAdd`. The command file:

1. Lists the CUDA devices, kernels, SMs, blocks, and threads with:

   ```text
   info cuda devices
   info cuda kernels
   info cuda sms
   info cuda blocks
   info cuda threads
   ```

2. Selects the CUDA thread in block 3, thread 35 with:

   ```text
   cuda block 3 thread 35
   ```

   and prints `blockIdx`, `threadIdx`, `i`, `A[i]`, and `B[i]`.

3. Lists the warps and lanes with `info cuda warps` and `info cuda lanes`.

4. Uses `next 3` to let the selected CUDA thread finish; the breakpoint is then
   hit again in block 0, thread 0.

5. Selects block 14, thread 66, which is outside the valid range (`i = 1004`),
   and prints its indices.

6. Selects the same area by warp and lane with `cuda warp 2 lane 1` (block 14,
   thread 65, `i = 1003`), demonstrating an alternative way to choose a CUDA
   thread, and uses `next` to show that the `if (i < size)` condition is false.

The second breakpoint is inside `vectorAddStride`. The command file:

1. Continues to the grid-stride kernel and lists the CUDA threads again.
2. Selects block 3, thread 70 (`tid = 283`) and prints `blockIdx`,
   `threadIdx`, `tid`, `stride`, and `i`.
3. Uses `display i` and repeated `next` commands to follow this thread through
   its iterations: `i = 283, 638, 993`.
4. Removes the display and selects `cuda sm 8 warp 3 lane 31` (block 4,
   thread 31, `tid = 315`).
5. Follows this thread through its iterations: `i = 315, 670`.
6. Continues to the end of the program and quits CUDA-GDB.

Note that CUDA-GDB single-stepping operates at warp granularity, and the exact
thread values can depend on the GPU and runtime.

## OpenACC example: vectoraddacc

### Files

| File | Purpose |
| --- | --- |
| [`../src/vectoraddacc.cpp`](../src/vectoraddacc.cpp) | C++20 OpenACC program for vector addition |
| [`commands_cuda-gdb_vectoraddacc_omp.txt`](commands_cuda-gdb_vectoraddacc_omp.txt) | CUDA-GDB command file for the OpenACC and OpenMP sessions |
| [`compile_run_cuda-gdb.sh`](compile_run_cuda-gdb.sh) | Builds the examples and runs CUDA-GDB with the command files |
| [`output/output_vectoraddacc.txt`](output/output_vectoraddacc.txt) | Captured CUDA-GDB output of the OpenACC session |
| [`cuda-gdb_cheat_sheet.md`](cuda-gdb_cheat_sheet.md) | Cheat sheet for the CUDA-GDB commands used in this example |

### The example program

`../src/vectoraddacc.cpp` is a C++20 program that uses OpenACC to offload the
vector addition to the GPU. It uses `std::vector`, `std::iota`,
`std::ranges::transform`, `std::views::iota`, and `std::format`.

The program uses `vec_size = 999` and prints the first `print_size = 10`
results. It fills `A` with `0..998` and `B` with twice those values, then
performs the addition in an OpenACC region:

```cpp
#pragma acc parallel loop copyin(A_ptr[0 : vec_size], B_ptr[0 : vec_size]) copyout(C_ptr[0 : vec_size])
for (unsigned int i = 0; i < vec_size; ++i)
{
    C_ptr[i] = A_ptr[i] + B_ptr[i];
}
```

The compiler generates a CUDA kernel with 8 blocks of 128 threads (1024
threads). The last 25 threads are outside the valid range. The program prints
the OpenACC version (`201711`) and the first ten results.

### The debugging session

`commands_cuda-gdb_vectoraddacc_omp.txt` is run with `cuda-gdb -x`. It enables
command tracing with `set trace-commands on`, sets a breakpoint at line 41, and
then runs the program.

The command file:

1. Lists the CUDA devices and kernels with:

   ```text
   info cuda devices
   info cuda kernels
   ```

2. Echoes the launch configuration: `8 × 128 = 1024` CUDA threads, with each
   loop iteration handled by one CUDA thread.

3. Lists the SMs, blocks, and threads with:

   ```text
   info cuda sms
   info cuda blocks
   info cuda threads
   ```

4. Selects the CUDA thread in block 3, thread 35 with:

   ```text
   cuda block 3 thread 35
   ```

   and prints `blockIdx`, `threadIdx`, `i` (`419`), `A_ptr[i]` (`419`), and
   `B_ptr[i]` (`838`).

5. Lists the warps and lanes with `info cuda warps` and `info cuda lanes`.

6. Uses `next` to let the selected CUDA thread finish.

7. Selects block 7, thread 127 (`i = 1023`), which is outside the valid range,
   and shows that the last warp is partially divergent.

8. Continues to the end of the program and quits CUDA-GDB.

The same command file is used for the OpenMP variant `vectoraddomp`.

## OpenMP example: vectoraddomp

### Files

| File | Purpose |
| --- | --- |
| [`../src/vectoraddomp.cpp`](../src/vectoraddomp.cpp) | C++20 OpenMP GPU offloading program for vector addition |
| [`commands_cuda-gdb_vectoraddacc_omp.txt`](commands_cuda-gdb_vectoraddacc_omp.txt) | CUDA-GDB command file for the OpenACC and OpenMP sessions |
| [`compile_run_cuda-gdb.sh`](compile_run_cuda-gdb.sh) | Builds the examples and runs CUDA-GDB with the command files |
| [`output/output_vectoraddomp.txt`](output/output_vectoraddomp.txt) | Captured CUDA-GDB output of the OpenMP session |
| [`cuda-gdb_cheat_sheet.md`](cuda-gdb_cheat_sheet.md) | Cheat sheet for the CUDA-GDB commands used in this example |

### The example program

`../src/vectoraddomp.cpp` is a C++20 program that uses OpenMP GPU offloading to
perform the vector addition. It uses `std::vector`, `std::iota`,
`std::ranges::transform`, `std::views::iota`, and `std::format`.

The program uses `vec_size = 999` and prints the first `print_size = 10`
results. It fills `A` with `0..998` and `B` with twice those values, then
performs the addition in an OpenMP target region:

```cpp
#pragma omp target teams distribute parallel for map(to : A_ptr[0 : vec_size], B_ptr[0 : vec_size]) map(from : C_ptr[0 : vec_size])
for (unsigned int i = 0; i < vec_size; ++i)
{
    C_ptr[i] = A_ptr[i] + B_ptr[i];
}
```

The compiler generates a CUDA kernel with 8 blocks of 128 threads (1024
threads). The last 25 threads are outside the valid range. The generated kernel
is `nvkernel_main_F1L39_2<<<(8,1,1),(128,1,1)>>>`. The program prints the
OpenMP version (`202011`) and the first ten results.

### The debugging session

`commands_cuda-gdb_vectoraddacc_omp.txt` is run with `cuda-gdb -x`. It enables
command tracing with `set trace-commands on`, sets a breakpoint at line 41, and
then runs the program.

The session follows the same steps as the OpenACC example:

1. Lists the CUDA devices and kernels with:

   ```text
   info cuda devices
   info cuda kernels
   ```

2. Echoes the launch configuration: `8 × 128 = 1024` CUDA threads, with each
   loop iteration handled by one CUDA thread.

3. Lists the SMs, blocks, and threads with:

   ```text
   info cuda sms
   info cuda blocks
   info cuda threads
   ```

4. Selects the CUDA thread in block 3, thread 35 with:

   ```text
   cuda block 3 thread 35
   ```

   and prints `blockIdx`, `threadIdx`, `i` (`419`), `A_ptr[i]` (`419`), and
   `B_ptr[i]` (`838`).

5. Lists the warps and lanes with `info cuda warps` and `info cuda lanes`.

6. Uses `next` to let the selected CUDA thread finish.

7. Selects block 7, thread 127 (`i = 1023`), which is outside the valid range,
   and shows that the last warp is partially divergent.

8. Continues to the end of the program and quits CUDA-GDB. After the final
   `next`, the OpenMP runtime switches focus back to block 0, thread 0 and
   stops at the breakpoint again before `continue` completes the program.

The same command file is used for the OpenACC variant `vectoraddacc`.

## Compile and run

Run the script from this directory:

```bash
./compile_run_cuda-gdb.sh
```

The script builds all examples:

```bash
nvcc -std=c++20 -g -G -O0 -o build/vectoradd ../src/vectoradd.cu
nvc++ -std=c++20 -g -O0 -acc -gpu=debug -Minfo=accel -o build/vectoraddacc ../src/vectoraddacc.cpp
nvc++ -std=c++20 -g -O0 -mp=gpu -gpu=debug -Minfo=mp -o build/vectoraddomp ../src/vectoraddomp.cpp
```

and runs CUDA-GDB with the command files:

```bash
cuda-gdb -x commands_cuda-gdb_vectoradd.txt ./build/vectoradd > build/output_vectoradd.txt 2>&1
cuda-gdb -x commands_cuda-gdb_vectoraddacc_omp.txt ./build/vectoraddacc > build/output_vectoraddacc.txt 2>&1
cuda-gdb -x commands_cuda-gdb_vectoraddacc_omp.txt ./build/vectoraddomp > build/output_vectoraddomp.txt 2>&1
```

The sessions are written to `build/output_vectoradd.txt`,
`build/output_vectoraddacc.txt`, and `build/output_vectoraddomp.txt`.

The files in [`output/`](output/) are captured reference transcripts of the
sessions; they are not updated automatically by the script.
