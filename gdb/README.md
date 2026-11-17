# GDB: segmentation fault example

See the [GDB cheat sheet](gdb_cheat_sheet.md) for a reference of the commands
used here.

## Table of contents

- [Files](#files)
- [The example program](#the-example-program)
- [The debugging session](#the-debugging-session)
- [Compile and run](#compile-and-run)

## Files

| File | Purpose |
| --- | --- |
| [`../src/examplesegfault.c`](../src/examplesegfault.c) | C23 program that triggers the segmentation fault |
| [`commands_gdb_examplesegfault.txt`](commands_gdb_examplesegfault.txt) | GDB command file for the debugging session |
| [`compile_run_gdb.sh`](compile_run_gdb.sh) | Builds the program and runs GDB with the command file |
| [`output/output_examplesegfault.txt`](output/output_examplesegfault.txt) | Captured GDB output of the session |
| [`gdb_cheat_sheet.md`](gdb_cheat_sheet.md) | Cheat sheet for the GDB commands used in this example |

## The example program

`../src/examplesegfault.c` is a small C23 program. It uses the C23 keyword
`nullptr` and has three functions:

- `modify(int **ptr)` sets `*ptr` to `nullptr` when `**ptr` is odd, and returns
  early when `ptr` or `*ptr` is already null.
- `calculate(int *ptr)` calls `modify(&ptr)` and then writes `99` through the
  pointer (`*ptr = 99`).
- `main()` creates `number = 4` and `data = &number`, then calls `calculate()`
  twice with the same pointer.

On the first call, `**ptr` is `4` (even), so `modify()` leaves the pointer
alone and `calculate()` changes the integer to `99`. On the second call, `**ptr`
is `99` (odd), so `modify()` sets `calculate()`'s local `ptr` to `nullptr`. The
write at line 16 then dereferences the null pointer and raises `SIGSEGV`.

## The debugging session

`commands_gdb_examplesegfault.txt` is run with `gdb -x`. It proposes this
workflow:

1. Identify the fault: run the program, list the failing source lines, and
   inspect the call stack with `backtrace`.
2. Inspect the failing statement: set breakpoints in `main()` and at line 16,
   enable reverse debugging with `record full`, and examine threads, local
   variables, arguments, and the pointer (`whatis`, `print`, `print *ptr`).
   Continue to the second call and step into the fault. Remove the line-16
   breakpoint, then use `reverse-step` to enter `modify()` and `reverse-next` to
   move back to the statement that set the pointer to `nullptr`.
3. Investigate the root cause: break in `modify()` at line 9, inspect its
   arguments and locals, and evaluate the condition `**ptr % 2` on both calls:
   `4 % 2 == 0` on the first call and `99 % 2 == 1` on the second call.
4. Test a hypothesis: change the integer to the even value `6` with
   `set var **ptr=6` and continue. `modify()` no longer nulls the pointer, so
   the program exits normally.
5. Clean up: delete the breakpoints and quit GDB.

## Compile and run

Run the script from this directory:

```bash
./compile_run_gdb.sh
```

The script builds the example:

```bash
gcc -std=c2x -g -O0 -o build/examplesegfault ../src/examplesegfault.c
```

and runs GDB with the command file:

```bash
gdb -x commands_gdb_examplesegfault.txt ./build/examplesegfault > build/output_examplesegfault.txt 2>&1
```

The GDB session is written to `build/output_examplesegfault.txt` by the
script. The file
[`output/output_examplesegfault.txt`](output/output_examplesegfault.txt) is a
captured reference transcript of the session; it is not updated automatically
by `compile_run_gdb.sh`.
