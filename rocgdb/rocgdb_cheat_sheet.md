# ROCgdb Cheat Sheet

ROCgdb is AMD's source-level debugger for ROCm host (CPU) and device (GPU) code.
It is based on GNU GDB, so standard GDB commands work unchanged. This cheat
sheet covers HIP/ROCm-specific and GPU-specific commands and behavior; common
host-debugging commands are documented in
[`gdb/gdb_cheat_sheet.md`](../gdb/gdb_cheat_sheet.md). See the
[ROCgdb documentation](https://rocm.docs.amd.com/projects/ROCgdb/en/latest/)
for the complete command reference.

Commands use `program` as the program name. Source file names and paths are
illustrative; adapt them to your project.

## Table of contents

- [1. Command reference](#1-command-reference)
- [2. Compile with HIP/ROCm debugging information](#2-compile-with-hiprocm-debugging-information)
- [3. Start ROCgdb](#3-start-rocgdb)
- [4. GPU state and focus](#4-gpu-state-and-focus)
- [5. Software and hardware views](#5-software-and-hardware-views)
- [6. HIP/ROCm debugging notes](#6-hiprocm-debugging-notes)

## 1. Command reference

The commands below are HIP/ROCm-specific or have a GPU-specific meaning in
ROCgdb. Standard GDB commands are documented in the GDB cheat sheet;
`info threads` and `thread <id>` are repeated here because their GPU meaning
differs from host-only GDB.

| Command | Description |
| --- | --- |
| **Starting ROCgdb** | |
| `rocgdb <program>` | Start ROCgdb with a program |
| `rocgdb -x <command-file> <program>` | Start ROCgdb and execute the commands in a command file |
| **Session settings** | |
| `set width unlimited` | Disable line wrapping at the terminal width |
| **Agents, queues, and dispatches** | |
| `show architecture` | Display the current target architecture; reports `amdgcn:gfx942` when stopped in device code |
| `info agents` | List AMD GPU agents with architecture, device name, cores (SIMD units), threads (maximum wavefront residency capacity), and location |
| `info queues` | List heterogeneous queues with their type, read/write indices, size, and address |
| `info dispatches` | List kernel dispatches with grid, work-group, fence, and kernel function |
| **Wavefronts and lanes** | |
| `info threads` | List host threads and GPU wavefronts |
| `thread <id>` | Select host thread or GPU wavefront `<id>` |
| `info lanes` | List the used lanes of the current wavefront; `-all` also lists unused lanes |
| `lane <N>` | Select lane `<N>` in the current wavefront |
| **HIP built-in variables** | |
| `print threadIdx` | Display the work-item index; use `.x`, `.y`, `.z` for a component |
| `print blockIdx` | Display the work-group index; use `.x`, `.y`, `.z` for a component |
| `print blockDim` | Display the work-group dimensions |
| `print gridDim` | Display the grid dimensions |
| **Wavefront scheduling** | |
| `set scheduler-locking <mode>` | Control which wavefronts run; `on` runs only the current wavefront, `replay` restores the default, `off` disables locking, and `step` locks only while stepping |
| **ROCm-specific diagnostics** | |
| `show amdgpu version` | Display the ROCdbgapi library version and path |
| `set amdgpu precise-memory <mode>` | Control precise reporting of memory violations; `on` improves fault locations but can be slower |
| `show amdgpu precise-memory` | Display the requested and effective precise-memory setting |

ROCgdb represents each GPU wavefront as a thread. The `info threads` output
therefore contains both host threads and GPU wavefronts, and `thread <id>` can
select either. After selecting a wavefront, use `info lanes` and `lane <N>` to
inspect and select its work-items.

## 2. Compile with HIP/ROCm debugging information

Use `amdclang++` for HIP (`.hip`) files:

```bash
amdclang++ -std=c++20 -ggdb -O0 -x hip --offload-arch=gfx942 program.hip -o program
```

Use `amdclang++` with `-fopenmp` for C++ (`.cpp`) files that use OpenMP GPU
offloading:

```bash
amdclang++ -std=c++20 -ggdb -O0 -fopenmp --offload-arch=gfx942 program.cpp -o program
```

Explanation:

- `-ggdb`: Debugging symbols for host and device code.
- `-O0`: Disable compiler optimizations. Optimized device code can prevent
  ROCgdb from stopping at the expected source lines.
- `--offload-arch=gfx942`: Target AMD GPU architecture. Use the architecture
  reported by `rocminfo` or by `show architecture` in ROCgdb; repeat the option
  for multiple GPU architectures.
- `-x hip`: Compile the input as HIP.
- `-fopenmp`: Enable OpenMP GPU offloading.

`amdclang++` is the recommended ROCm compiler; the legacy `hipcc` wrapper is
deprecated. The examples in this repository were compiled and run on an AMD
Instinct MI300A (`gfx942`). Use the architecture that matches your GPU rather
than `gfx942`; see the
[LLVM AMDGPU usage documentation](https://llvm.org/docs/AMDGPUUsage.html) for
the correct `gfx` target name.

## 3. Start ROCgdb

Start ROCgdb with the compiled program:

```bash
rocgdb ./program
```

You should see the ROCgdb prompt:

```text
(rocgdb)
```

To run a command file at startup:

```bash
rocgdb -x commands.txt ./program
```

Command files are useful for reproducible debugging sessions. They may also
contain standard GDB commands, which are documented in the GDB cheat sheet.
Most standard GDB startup options also work; see the GDB cheat sheet for
details.

`info agents` does not list any agents until the inferior has started executing
the program.

## 4. GPU state and focus

When a breakpoint in a HIP kernel is hit, ROCgdb switches focus to a GPU
wavefront and reports the wavefront, lane, dispatch, and work-group:

```text
[Switching to thread 6, lane 0 (AMDGPU Lane 1:1:1:1/0 (2,0,0)[0,0,0])]

Thread 6 "vectorAdd" hit Breakpoint 1, with lanes [0-63], vectorAdd
    (...) at ../src/vectoradd.hip:35
```

### 4.1 List agents, queues, and dispatches

```text
(rocgdb) show architecture
The target architecture is set to "auto" (currently "amdgcn:gfx942").

(rocgdb) info agents
  Id State Target Id                  Architecture Device Name         Cores Threads Location
* 1  A     AMDGPU Agent (GPUID 47157) gfx942       AMD Instinct MI300A 912   7296    0000:02:00.0

(rocgdb) info queues
  Id   Target Id                Type         Read   Write  Size     Address
* 1    AMDGPU Queue 1:1 (QID 1) HSA          5      7      1048576  0x00007fffb9200000
  2    AMDGPU Queue 1:2 (QID 0) HSA          4      4      4096     0x00007fffebe6e000

(rocgdb) info dispatches
  Id   Target Id                      Grid       Workgroup Fence   Kernel Function
* 1    AMDGPU Dispatch 1:1:1 (PKID 5) [1005,1,1] [67,1,1]  B|As|Rs vectorAdd(...)
```

`info agents` reports the AMD GPU agents visible to ROCgdb, including their
architecture, device name, cores (SIMD units), threads (maximum wavefront
residency capacity), and PCI location. The queue types reported by
`info queues` can include HSA, PM4, DMA, and XGMI.

In `info dispatches`, `Grid` is the total number of work-items
(`number of work-groups * work-group size`) and `Workgroup` is the per-group
size, shown as `x,y,z`. For 1-D launches, trailing dimensions can be omitted,
as in `[1024]` and `[32]`. In the example above, `[1005,1,1]` and `[67,1,1]`
correspond to 15 work-groups of 67 work-items.

### 4.2 List and select wavefronts and lanes

```text
(rocgdb) info threads
  Id   Target Id                              Frame
  ...
  13   AMDGPU Wave 1:1:1:8 (3,0,0)/1 "vectorAdd"  vectorAdd (...) at ../src/vectoradd.hip:35

(rocgdb) thread 13
[Switching to thread 13, lane 0 (AMDGPU Lane 1:1:1:8/0 (3,0,0)[64,0,0])]

(rocgdb) info lanes
  Id   State Target Id                             Frame
  * 0    A     AMDGPU Lane 1:1:1:8/0 (3,0,0)[64,0,0] vectorAdd (...) at ../src/vectoradd.hip:35
    1    A     AMDGPU Lane 1:1:1:8/1 (3,0,0)[65,0,0] vectorAdd (...) at ../src/vectoradd.hip:35
    2    A     AMDGPU Lane 1:1:1:8/2 (3,0,0)[66,0,0] vectorAdd (...) at ../src/vectoradd.hip:35

(rocgdb) lane 2
[Switching to thread 13, lane 2 (AMDGPU Lane 1:1:1:8/2 (3,0,0)[66,0,0])]
```

For a GPU entry, `thread <id>` selects a wavefront, not an individual
work-item. `lane <N>` selects a work-item within the current wavefront. For
example, on the captured AMD Instinct MI300A (`gfx942`) system, a wavefront has
64 lanes, so 67 work-items per work-group occupy two wavefronts per work-group:
one full 64-lane wavefront and one wavefront that uses 3 lanes. See
[Software and hardware views](#5-software-and-hardware-views) for the
distinction between the two views.

### 4.3 Inspect HIP built-in variables

Once a wavefront and lane are selected, inspect the HIP execution coordinates
and device variables:

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

For the same `vectorAdd` launch, the work-group and grid dimensions are:

```text
(rocgdb) print blockDim
$6 = {x = 67, y = 1, z = 1}
(rocgdb) print gridDim
$7 = {x = 15, y = 1, z = 1}
```

`threadIdx` is the per-work-item index; `blockIdx` is the per-work-group index
and is shared by all wavefronts of a work-group. Use `print threadIdx.x`,
`print blockIdx.x`, and so on to inspect a single component.

### 4.4 Wavefront scheduling and single-stepping

ROCgdb single-steps at wavefront granularity, not independently for each lane.
When `next` resumes the current wavefront, another wavefront can hit the same
breakpoint first:

```text
(rocgdb) next
[Switching to thread 26, lane 0 (AMDGPU Lane 1:1:1:21/0 (6,0,0)[0,0,0])]

Thread 26 "vectorAdd" hit Breakpoint 1, with lanes [0-63], ...
```

To keep the selected wavefront running while other wavefronts stay stopped,
enable scheduler locking:

```text
(rocgdb) set scheduler-locking on
(rocgdb) next
(rocgdb) next
```

If a breakpoint keeps stopping other wavefronts while you inspect the current
one, disable it after the first hit. In general, prefer a line breakpoint (for
example, `break vectoradd.hip:35`) over a function breakpoint to catch every
wavefront at the same source line; a function breakpoint can stop in the middle
of the prologue.

Restore the default scheduling when finished:

```text
(rocgdb) set scheduler-locking replay
```

`replay` is the default mode. It behaves like `off` during normal execution
and like `on` in replay mode.

### 4.5 Wavefront and lane target IDs

ROCgdb identifies wavefronts and lanes with the following target ID formats:

```text
AMDGPU Wave agent-id:queue-id:dispatch-id:wave-id (work-group-x,work-group-y,work-group-z)/work-group-thread-index

AMDGPU Lane agent-id:queue-id:dispatch-id:wave-id/lane-index (work-group-x,work-group-y,work-group-z)[work-item-x,work-item-y,work-item-z]
```

For example:

- `AMDGPU Wave 1:1:1:8 (3,0,0)/1` is wavefront 8 of dispatch 1 on agent 1. It
  belongs to work-group `(3,0,0)` and is work-group-thread-index 1.
- `AMDGPU Lane 1:1:1:8/2 (3,0,0)[66,0,0]` is lane 2 of that wavefront. It
  corresponds to work-item `(66,0,0)` in the work-group.

## 5. Software and hardware views

GPU execution can be described from two views:

- **Software view:** the program launches a grid of work-groups, and each
  work-group contains work-items. HIP exposes the work-group and work-item
  coordinates and dimensions through `blockIdx`, `blockDim`, `gridDim`, and
  `threadIdx`. OpenMP exposes the same concepts through teams and threads.
- **Hardware view:** the GPU executes wavefronts, and each wavefront contains
  lanes. ROCgdb single-steps at wavefront granularity; each used lane
  corresponds to one work-item.

On AMD GPUs, wavefronts are scheduled for execution on the SIMD units of a
Compute Unit (CU). The hardware hierarchy is:

- **Compute Unit (CU):** the hardware unit that schedules and executes
  wavefronts.
- **SIMD unit:** the 16-lane vector execution unit within a CU. For example, the
  AMD Instinct MI300A has four SIMD units per CU, each 16 lanes wide.
- **Stream Processor (SP):** an individual lane datapath within a SIMD unit.
  Each 16-lane SIMD unit has 16 SPs, giving 64 SPs per CU (and 14,592 in total).
  These SPs also execute FP64 vector instructions, but at a lower rate.
- **Wavefront:** a group of lanes executed together by a SIMD unit. On CDNA GPUs
  such as the AMD Instinct MI300A, a wavefront has 64 lanes and executes over
  4 cycles on a single 16-lane SIMD unit. A wavefront is bound to one SIMD unit
  and cannot be split across multiple SIMDs; the CU achieves full throughput by
  interleaving execution of different wavefronts across its four SIMD units.
- **Lane:** an individual execution position within a wavefront:
  - **Used vs. unused:** a used lane corresponds to one work-item; an unused
    lane (e.g. at the end of a partial wavefront) has no work-item and is hidden
    in `info lanes` by default.
  - **Active vs. inactive:** an active lane is currently executing instructions;
    an inactive lane is temporarily masked out by branch divergence, but still
    corresponds to its work-item.

A few important details:

- A work-group is assigned to a single CU, and its wavefronts execute on that
  CU.
- Multiple wavefronts from the same or different work-groups can reside on the
  same CU.
- A CU can keep multiple wavefronts resident and issue instructions from several
  of them concurrently. Residency is limited by resources such as registers and
  LDS; the CU issues instructions to its SIMD units, which execute concurrently.
- SPs represent physical arithmetic execution resources. Their number is not the
  number of concurrently resident work-items.

### 5.1 ROCgdb hardware information

In ROCgdb, `info agents` reports the hardware resources of each GPU agent
through the `Cores` and `Threads` columns, which must be interpreted with care.

The captured AMD Instinct MI300A reports:

```text
  Id State Target Id                  Architecture Device Name         Cores Threads Location
* 1  A     AMDGPU Agent (GPUID 47157) gfx942       AMD Instinct MI300A 912   7296    0000:02:00.0
```

In this output:

- **ROCgdb `Cores`:** number of SIMD units.
- **ROCgdb `Threads`:** maximum wavefront residency capacity.

The relationship between the reported values and the hardware architecture is:

- 228 Compute Units.
- 4 SIMD units per Compute Unit.
- 912 SIMD units in total (ROCgdb `Cores`).
- 8 wavefronts can be resident per SIMD unit.
- 7,296 wavefronts can be resident in total (ROCgdb `Threads`); this is the
  maximum wavefront residency capacity.
- 16 Stream Processors per SIMD unit.
- 14,592 Stream Processors in total.

Thus:

```text
Number of Compute Units      = 912 / 4  = 228
Wavefront capacity           = 912 * 8  = 7,296
Number of Stream Processors  = 912 * 16 = 14,592
```

**FP32 vs. FP64:** The Stream Processor count is an FP32 lane-datapath count. On
the AMD Instinct MI300A, FP64 vector operations execute on the same SIMD units
at half the FP32 rate (61.3 TFLOPS versus 122.6 TFLOPS). FP64 matrix operations
use the matrix cores instead and reach 122.6 TFLOPS. Thus 14,592 is not a count
of dedicated FP64 units.

**Important distinction:** The maximum wavefront residency capacity is a
theoretical limit; actual residency is reduced by the register and LDS
requirements of the resident work-groups. It is not the number of HIP work-items
or wavefront lanes. Likewise, it should not be interpreted directly as the
number of simultaneously executing wavefronts.

### 5.2 Mapping between software and hardware views

The mapping between the two views is not one-to-one. A work-group is decomposed
into one or more wavefronts, and a wavefront is not necessarily fully used.

For example, on the captured AMD Instinct MI300A (`gfx942`) system, a wavefront
has 64 lanes. A work-group with 67 work-items therefore occupies two wavefronts:
one full wavefront and one that uses only 3 lanes. The other 61 lanes of the
second wavefront have no work-item and are unused. ROCgdb hides unused lanes in
`info lanes` by default; use `info lanes -all` to include them.

For a 64-lane wavefront, the block-relative wavefront and lane can be derived
from the work-item's position in its work-group: for a work-group of
`blockDim.x` by `blockDim.y` by `blockDim.z` work-items, the linear work-item
index is `threadIdx.x + blockDim.x * (threadIdx.y + blockDim.y * threadIdx.z)`,
the block-relative wavefront is that index divided by 64 (integer division), and
the lane is that index modulo 64. The `wave-id` in ROCgdb's target ID is
assigned when the wavefront is created and is not the block-relative wavefront
index. In the captured `vectorAdd` launch, work-group 3's second wavefront is
block-relative wavefront 1, but ROCgdb reports it as wave 8.

ROCgdb exposes the hardware view through `info threads` and `info lanes`, while
`blockIdx`, `threadIdx`, and the other built-in variables report the software
view. `thread <id>` selects a wavefront, whereas `lane <N>` selects a work-item
within that wavefront. `set scheduler-locking` controls which wavefronts run
when execution resumes; it does not itself report hardware state.

## 6. HIP/ROCm debugging notes

- Host and device debugging share one session. Use the standard GDB
  `thread <id>` and `frame [N]` commands for host threads, and `thread <id>`
  plus `lane <N>` for GPU wavefronts and work-items.
- Inactive lanes appear in `info lanes` with state `I` and the text
  `(inactive)`. Selecting an inactive lane can produce the warning
  `Current lane is inactive`. Lanes with no work-item (for example, the
  leftover lanes of a partial wavefront) are unused and are hidden by
  `info lanes` unless `-all` is specified.
- The HIP runtime uses deferred code-object loading, so kernel breakpoints may
  be pending until the first kernel launch. Use function-name breakpoints, or
  enable pending breakpoints with `set breakpoint pending on` (documented in
  the GDB cheat sheet). Setting `HIP_ENABLE_DEFERRED_LOADING=0` makes the
  runtime load code objects when the inferior reaches `main`.
- When stopped in device code, register inspection shows the current
  wavefront's general-purpose registers. `info all-registers` includes all AMD
  GPU register groups. See the GDB cheat sheet for the standard register
  commands.
- AMD GPU address spaces can be selected with the `global#`, `local#`,
  `generic#`, `private_wave#`, and `private_lane#` qualifiers:

  ```text
  (rocgdb) x/8x global#0x7fffe6e00000
  (rocgdb) x/8x local#0x0
  (rocgdb) x/8x private_lane#0x0
  ```

- Memory violation reporting is not precise by default. Enable precise
  reporting when the reported source location must be exactly after the
  faulting instruction:

  ```text
  (rocgdb) set amdgpu precise-memory on
  (rocgdb) show amdgpu precise-memory
  ```

  Precise reporting can be significantly slower and cannot be enabled if the
  available AMD GPU devices do not support it.

- Display the loaded ROCdbgapi version and path with:

  ```text
  (rocgdb) show amdgpu version
  ```

- The available commands and their behavior depend on the GPU, driver, ROCm
  version, and ROCgdb version. ROCgdb does not support `gdbserver`. The AMD GPU
  target does not currently support calling inferior functions.
