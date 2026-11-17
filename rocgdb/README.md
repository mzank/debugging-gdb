# ROCgdb: vector addition examples

See the [ROCgdb cheat sheet](rocgdb_cheat_sheet.md) for a reference of the
commands used here.

## Table of contents

- [HIP example: vectoradd](#hip-example-vectoradd)
- [OpenMP example: vectoraddomp](#openmp-example-vectoraddomp)
- [Compile and run](#compile-and-run)

## HIP example: vectoradd

### Files

| File | Purpose |
| --- | --- |
| [`../src/vectoradd.hip`](../src/vectoradd.hip) | C++20 HIP program for vector addition |
| [`commands_rocgdb_vectoradd.txt`](commands_rocgdb_vectoradd.txt) | ROCgdb command file for the HIP session |
| [`compile_run_rocgdb.sh`](compile_run_rocgdb.sh) | Builds the examples and runs ROCgdb with the command files |
| [`output/output_vectoradd.txt`](output/output_vectoradd.txt) | Captured ROCgdb output of the HIP session |
| [`rocgdb_cheat_sheet.md`](rocgdb_cheat_sheet.md) | Cheat sheet for the ROCgdb commands used in this example |

### The example program

`../src/vectoradd.hip` is a C++20 HIP program that adds two vectors on the GPU. It
uses `std::array`, `std::iota`, `std::ranges::transform`, `std::views::iota`,
and `std::format` on the host side.

The program uses `vec_size = 999` and prints the first `print_size = 10`
results. It initializes `h_A` with `0..998` and `h_B` with twice those values,
allocates the device arrays with `hipMalloc`, copies the inputs to the GPU, and
clears the result arrays with `hipMemset`. The helper `hipCheck()` reports
errors returned by HIP API calls.

The file defines two HIP kernels:

- `vectorAdd` computes one element per work-item:

  ```cpp
  unsigned int const i{blockIdx.x * blockDim.x + threadIdx.x};

  if (i < size)
  {
      C[i] = A[i] + B[i];
  }
  ```

  It is launched with 15 work-groups of 67 work-items, giving 1005 work-items
  for 999 elements.

- `vectorAddStride` uses a grid-stride loop:

  ```cpp
  unsigned int const tid{blockIdx.x * blockDim.x + threadIdx.x};
  unsigned int const stride{blockDim.x * gridDim.x};

  for (unsigned int i = tid; i < size; i += stride)
  {
      C[i] = A[i] + B[i];
  }
  ```

  It is launched with 5 work-groups of 71 work-items (355 work-items), so each
  work-item processes multiple elements.

Both kernels store their results in separate device arrays. The host copies
the results back with `hipMemcpy` and prints the first ten rows for each
approach.

On the captured AMD Instinct MI300A (`gfx942`) system, a wavefront has 64
lanes. A work-group of 67 work-items therefore occupies two wavefronts: one
full 64-lane wavefront and one that uses 3 lanes. The first kernel thus runs
as 30 wavefronts, and the second as 10 wavefronts.

### The debugging session

`commands_rocgdb_vectoradd.txt` is run with `rocgdb -x`. It enables command
tracing with `set trace-commands on`, enables pending breakpoints with
`set breakpoint pending on`, disables line wrapping with `set width unlimited`,
sets breakpoints at lines 35 and 51, and then runs the program.

The kernel breakpoints are reported as pending because HIP loads code objects
lazily:

```text
+break 35
No compiled code for line 35 in the current file.
Breakpoint 1 (35) pending.
```

The first breakpoint is inside `vectorAdd`. The command file:

1. Lists the GPU architecture, agents, queues, dispatches, and threads with:

   ```text
   show architecture
   info agents
   info queues
   info dispatches
   info threads
   ```

   The dispatch is `[1005,1,1]` with work-group size `[67,1,1]`, i.e. 15
   work-groups of 67 work-items. In ROCgdb, each GPU entry in `info threads` is
   a wavefront, not an individual work-item.

2. Selects the second wavefront of work-group `(3,0,0)` with `thread 13` and
   then the work-item in that wavefront with `lane 2`. `info lanes` shows that
   only lanes 0, 1, and 2 are used on this wavefront (the other 61 lanes are
   unused and hidden by default). The selected lane
   corresponds to work-item `[66,0,0]`, and the command file prints:

   ```text
   (rocgdb) print blockIdx
   $1 = {x = 3, y = 0, z = 0}
   (rocgdb) print threadIdx
   $2 = {x = 66, y = 0, z = 0}
   (rocgdb) print i
   $3 = 267
   (rocgdb) print A[i]
   $4 = 267
   (rocgdb) print B[i]
   $5 = 534
   ```

3. Uses `next` once, which switches to another wavefront (`thread 26`) that
   hits the same breakpoint first. This shows that single-stepping operates at
   wavefront granularity.

4. Disables breakpoint 1 and enables `set scheduler-locking on`, so the other
   wavefronts stay stopped while the selected one is examined. The command file
   returns to `thread 13`, `lane 2`, and uses two `next` commands to step to
   `C[i] = A[i] + B[i]` (line 37) and the closing brace (line 39). This
   work-item is finished after processing exactly one index `i`.

5. Selects `thread 10`, which is wavefront 5 in work-group `(14,0,0)`, and
   `lane 63`, which is work-item `[63,0,0]`. Here `i = 1001`, which is outside
   the valid range. The following `next` moves past the `if` body, because the
   condition `i < size` is false.

6. Restores the default scheduling with `set scheduler-locking replay`, deletes
   breakpoint 1, and continues to the second kernel.

The second breakpoint is inside `vectorAddStride`. The command file:

1. Disables breakpoint 2 and lists the architecture, agents, queues,
   dispatches, and threads again. The dispatch is `[355,1,1]` with work-group
   size `[71,1,1]`, i.e. 5 work-groups of 71 work-items.

2. Selects `thread 44`, which is wavefront 39 in work-group `(1,0,0)`, and
   `lane 2`, which is work-item `[2,0,0]`. It prints `blockIdx`,
   `threadIdx`, and:

   ```text
   (rocgdb) print tid
   $9 = 73
   (rocgdb) print stride
   $10 = 355
   ```

3. Enables scheduler locking, uses `display i`, and follows this work-item
   through its loop iterations with repeated `next` commands:
   `i = 73, 428, 783`. After the third iteration, `i + stride` exceeds
   `size`, so the loop ends.

4. Selects `thread 41`, which is wavefront 36 in work-group `(4,0,0)`, and
   `lane 1`, which is work-item `[65,0,0]` (`tid = 349`). It follows this
   work-item through its iterations: `i = 349, 704`.

5. Removes the displays, deletes breakpoint 2, restores scheduling with
   `set scheduler-locking replay`, continues to the end of the program, and
   quits ROCgdb.

Note that exact thread IDs, wavefront assignments, and values can depend on the
GPU, driver, ROCm version, and ROCgdb version.

## OpenMP example: vectoraddomp

### Files

| File | Purpose |
| --- | --- |
| [`../src/vectoraddomp.cpp`](../src/vectoraddomp.cpp) | C++20 OpenMP GPU offloading program for vector addition |
| [`commands_rocgdb_vectoraddomp.txt`](commands_rocgdb_vectoraddomp.txt) | ROCgdb command file for the OpenMP session |
| [`compile_run_rocgdb.sh`](compile_run_rocgdb.sh) | Builds the examples and runs ROCgdb with the command files |
| [`output/output_vectoraddomp.txt`](output/output_vectoraddomp.txt) | Captured ROCgdb output of the OpenMP session |
| [`rocgdb_cheat_sheet.md`](rocgdb_cheat_sheet.md) | Cheat sheet for the ROCgdb commands used in this example |

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

The compiler generates the kernel
`__omp_offloading_37_2b4d86_main_l38_debug__` with 32 work-groups of 32
work-items (1024 work-items), so each loop iteration is handled by one
work-item. The last 25 work-items are outside the valid range. The program
prints the OpenMP version (`202011`) and the first ten results.

On the captured AMD Instinct MI300A (`gfx942`) system, a wavefront has 64
lanes. Work-groups and work-items are the software view; wavefronts and lanes
are the hardware view, and a wavefront is not necessarily fully used. A
work-group of 32 work-items occupies lanes 0-31 of one 64-lane wavefront; the
remaining lanes 32-63 have no work-item and are unused. `info lanes` hides
unused lanes by default. In the final work-group, only 7 work-items are valid,
so lanes 0-6 are active and lanes 7-31 are inactive.

### The debugging session

`commands_rocgdb_vectoraddomp.txt` is run with `rocgdb -x`. It enables command
tracing with `set trace-commands on`, enables pending breakpoints with
`set breakpoint pending on`, disables line wrapping with `set width unlimited`,
sets a breakpoint at line 41, and then runs the program.

Unlike the HIP example, the breakpoint resolves immediately at startup, since
the OpenMP offload code is already available:

```text
+break 41
Breakpoint 1 at 0x1890c: file ../src/vectoraddomp.cpp, line 41.
```

The subsequent hit is reported as `Breakpoint 1.2` because line 41 resolves to
multiple locations.

The command file:

1. Lists the GPU architecture, agents, queues, and dispatches with:

   ```text
   show architecture
   info agents
   info queues
   info dispatches
   ```

   The dispatch has grid `[1024]` and work-group size `[32]`, i.e. 32
   work-groups of 32 work-items.

2. Echoes the launch configuration: 32 * 32 = 1024 work-items, one per loop
   iteration.

3. Lists the threads with `info threads` and echoes a note that thread IDs
   represent wavefronts on the GPU.

4. Selects `thread 8`, which is wavefront 3 in work-group `(14,0,0)`. `info lanes`
   shows all 32 used lanes active. It then selects `lane 16`, which is work-item
   `[16,0,0]`. The command file prints:

   ```text
   (rocgdb) print blockIdx
   $1 = {x = 14, y = 0, z = 0}
   (rocgdb) print threadIdx
   $2 = {x = 16, y = 0, z = 0}
   (rocgdb) print i
   $3 = 464
   (rocgdb) print A_ptr[i]
   $4 = 464
   (rocgdb) print B_ptr[i]
   $5 = 928
   ```

5. Enables `set scheduler-locking on` and uses `next` to let this work-item
   finish. The breakpoint is hit again on the same wavefront.

6. Selects `thread 37`, which is wavefront 32 in the last work-group
   `(31,0,0)`, and inspects its lanes. Only lanes 0-6 are active; lanes 7-31
   are marked `I` (inactive). Selecting `lane 29` produces:

   ```text
   warning: Current lane is inactive.
   ```

   The command file still prints the full structs:
   `blockIdx = {x = 31, y = 0, z = 0}` and
   `threadIdx = {x = 29, y = 0, z = 0}`.

7. Uses `next`, which moves focus to lane 0 of the same wavefront. Only the
   active lanes 0-6 reach the breakpoint.

8. Restores scheduling with `set scheduler-locking replay`, deletes
   breakpoint 1, continues to the end of the program, and quits ROCgdb. The
   program prints `OpenMP version: 202011` and the result rows before exiting
   normally.

## Compile and run

Run the script from this directory:

```bash
./compile_run_rocgdb.sh
```

The examples were compiled and run on an AMD Instinct MI300A (`gfx942`). The
`--offload-arch=gfx942` flag must be adjusted to the actual AMD GPU in use; see
the [LLVM AMDGPU usage documentation](https://llvm.org/docs/AMDGPUUsage.html)
for the correct `gfx` target name.

The script builds the HIP example and the OpenMP example:

```bash
amdclang++ -std=c++20 -ggdb -O0 -x hip --offload-arch=gfx942 -o build/vectoradd ../src/vectoradd.hip
amdclang++ -std=c++20 -ggdb -O0 -fopenmp --offload-arch=gfx942 -o build/vectoraddomp ../src/vectoraddomp.cpp
```

and runs ROCgdb with the command files:

```bash
rocgdb -x commands_rocgdb_vectoradd.txt ./build/vectoradd > build/output_vectoradd.txt 2>&1
rocgdb -x commands_rocgdb_vectoraddomp.txt ./build/vectoraddomp > build/output_vectoraddomp.txt 2>&1
```

The sessions are written to `build/output_vectoradd.txt` and
`build/output_vectoraddomp.txt`. The files in [`output/`](output/) are captured
reference transcripts of the sessions; they are not updated automatically by
the script.
