# GDB Cheat Sheet

GDB (GNU Debugger) is a debugger for host (CPU) code. The GPU debuggers are
covered in the sibling cheat sheets
[`cuda-gdb/cuda-gdb_cheat_sheet.md`](../cuda-gdb/cuda-gdb_cheat_sheet.md) and
[`rocgdb/rocgdb_cheat_sheet.md`](../rocgdb/rocgdb_cheat_sheet.md).

## Table of contents

- [1. Command reference](#1-command-reference)
- [2. Compile with debugging information](#2-compile-with-debugging-information)
- [3. Start GDB](#3-start-gdb)
- [4. Breakpoints, watchpoints and catchpoints](#4-breakpoints-watchpoints-and-catchpoints)
- [5. Running and stepping](#5-running-and-stepping)
- [6. Understanding threads and stack frames](#6-understanding-threads-and-stack-frames)
- [7. Text User Interface (TUI)](#7-text-user-interface-tui)
- [8. Exit the debugger](#8-exit-the-debugger)

## 1. Command reference

Many command names can be abbreviated to an unambiguous prefix. For example,
`n` is short for `next`, `c` is short for `continue`, and `bt` is short for
`backtrace`. The most common abbreviations are shown in parentheses after the
full command name.

| Command | Description |
| --- | --- |
| **Starting GDB** | |
| `gdb <program>` | Start GDB with a program |
| `gdb <program> <core>` | Start GDB with a program and a core dump |
| `gdb --args <program> <args>` | Start GDB with program arguments |
| `gdb -x <command-file> <program>` | Start GDB and execute the commands in a command file |
| `source <command-file>` | Execute the commands in a command file during a session |
| `gdb -help` | Show GDB command-line options |
| `help <command>` (`h`) | Show help for a command |
| **Session scripting** | |
| `echo <text>` | Print text to the GDB output; use `\n` for a newline |
| `set trace-commands on` | Print each command before it executes |
| **Breakpoints, watchpoints and catchpoints** | |
| `break <where>` (`b`) | Set a breakpoint at a function, `file:line`, or line number |
| `break` (`b`) | Set a breakpoint at the current line |
| `break <where> if <condition>` | Set a conditional breakpoint |
| `break +<N>` / `break -<N>` | Set a breakpoint N lines after/before the current line |
| `tbreak <where>` (`tb`) | Set a temporary breakpoint, deleted after its first hit |
| `set breakpoint pending on` | Create pending breakpoints for locations not yet loaded |
| `catch signal SIGSEGV` | Stop when the `SIGSEGV` signal is received |
| `catch throw` | Stop when a C++ exception is thrown |
| `catch catch` | Stop when a C++ exception is caught |
| `catch syscall` | Stop when a system call occurs |
| `catch fork` | Stop when `fork()` is called |
| `catch exec` | Stop when `exec()` is called |
| `watch <expr>` | Stop when the value of an expression changes |
| `watch <expr> if <condition>` | Set a conditional watchpoint |
| `rwatch <expr>` | Stop when an expression is read |
| `awatch <expr>` | Stop when an expression is read or written |
| `info breakpoints` (`i b`) | List all breakpoints and watchpoints |
| `info watchpoints` | List all watchpoints |
| `disable <N>` | Disable breakpoint number N |
| `enable <N>` | Enable breakpoint number N |
| `delete [N]` (`d`) | Delete breakpoint N, or all breakpoints when N is omitted |
| `clear <where>` (`cl`) | Clear the breakpoint at a location |
| **Running and stepping** | |
| `run` (`r`) | Start the program and run until a breakpoint or fault |
| `start` | Start the program and stop at the beginning of `main()` |
| `continue` (`c`) | Resume execution until the next breakpoint |
| `next` (`n`) | Step over the next source line |
| `next <N>` | Step over the next N source lines |
| `step` (`s`) | Step into the next source line, entering functions |
| `until <N>` (`u`) | Continue execution until line N is reached |
| `finish` (`fin`) | Continue until the current function returns |
| `stepi` (`si`) | Step one machine instruction |
| `nexti` (`ni`) | Step over one machine instruction |
| `kill` | Kill the program being debugged |
| `quit` (`q`) | Exit GDB |
| **Reverse debugging** | |
| `record full` | Start recording execution; `target record-full` is the older form |
| `reverse-continue` (`rc`) | Execute backwards to the previous breakpoint or watchpoint |
| `reverse-step` (`rs`) | Execute backwards to the previous source-level step, entering functions |
| `reverse-next` (`rn`) | Execute backwards to the previous source-level step, without entering functions |
| **Stack frames** | |
| `backtrace` (`bt`) | Display the call stack |
| `frame [N]` (`f`) | Select stack frame N; without N, show the current frame |
| `up` | Move one frame towards the caller |
| `down` | Move one frame towards the currently executing function |
| `info frame` | Display information about the selected frame |
| `info args` | Display the function arguments of the selected frame |
| `info locals` | Display the local variables of the selected frame |
| **Data inspection** | |
| `print <expr>` (`p`) | Evaluate an expression, e.g. `print *ptr` or `print (variable*2 + 5)*variable` |
| `print /<format> <expr>` (`p/x`) | Print in a format, for example `p/x` for hexadecimal |
| `whatis <expr>` | Display the data type of an expression |
| `ptype <type>` | Display the definition of a type |
| `set var <variable>=<value>` | Assign a new value to a variable |
| `display <expr>` | Automatically display an expression each time execution stops |
| `undisplay <id>` | Stop automatically displaying an expression |
| `info registers` (`i r`) | Display the CPU register values |
| `x/10i $pc` | Display the next 10 instructions at the program counter |
| `disassemble` (`disas`) | Disassemble the current function |
| `list` (`l`) | List source lines |
| `list <first>,<last>` | List a range of source lines |
| `info functions` | List all defined function names |
| `info variables` | List all defined global and static variable names |
| `info pretty-printer` | List the registered pretty-printers |
| **Threads** | |
| `info threads` | List CPU threads |
| `thread <N>` | Switch to CPU thread N |
| **Text User Interface (TUI)** | |
| `tui enable` | Enable the TUI |
| `tui disable` | Disable the TUI and return to the normal interface |
| `layout src` (`lay src`) | Display source code |
| `layout asm` (`lay asm`) | Display assembly instructions |
| `layout split` (`lay split`) | Display source code and assembly simultaneously |
| `layout regs` (`lay regs`) | Display register information, where supported |
| `layout next` / `layout prev` | Switch to the next/previous layout |
| `refresh` (`ref`) | Redraw the TUI display |

## 2. Compile with debugging information

Use:

```bash
gcc -g -O0 program.c -o program
g++ -g -O0 program.cpp -o program
```

Explanation:

- `-g`: Debugging symbols for CPU code.
- `-O0`: Disable compiler optimizations.

Optimized code can reorder statements and remove variables, so use `-O0` while
debugging.

## 3. Start GDB

Start GDB with a program:

```bash
gdb ./program
```

Start GDB with a core dump:

```bash
gdb ./program core
```

Start GDB and pass arguments to the program:

```bash
gdb --args ./program arg1 arg2
```

Start GDB with a command file, which is executed at startup:

```bash
gdb -x commands.txt ./program
```

A command file can also be loaded during a session with `source`:

```text
(gdb) source commands.txt
```

You should see the interactive prompt:

```text
(gdb)
```

## 4. Breakpoints, watchpoints and catchpoints

Set a breakpoint in `main()` and one at a source line:

```text
(gdb) break main
(gdb) break program.c:16
```

Set a conditional breakpoint:

```text
(gdb) break calculate if ptr != 0
```

Catchpoints stop execution when a specific event occurs, such as a signal or an
exception. Catch a segmentation fault with:

```text
(gdb) catch signal SIGSEGV
```

Catchpoints apply to host (CPU) execution. See section 1 for the complete list
of breakpoint, watchpoint, and catchpoint commands.

## 5. Running and stepping

Start the program, then step through it:

```text
(gdb) run
(gdb) next
(gdb) step
(gdb) continue
```

Use `next` to step over function calls and `step` to step into them. Use
`finish` to run until the current function returns and `until <N>` to run to a
specific line.

For reverse debugging, start recording first:

```text
(gdb) record full
(gdb) continue
(gdb) reverse-next
(gdb) reverse-step
```

## 6. Understanding threads and stack frames

A stack frame represents one function invocation on the call stack. Whenever a
function calls another function, a new stack frame is created.

Each frame contains information about that particular function invocation,
including:

- Local variables.
- Function arguments.
- Return address.
- Saved registers and execution information.

### 6.1 Example

Consider the following C program:

```c
#include <stdlib.h>

void functionC()
{
    int c = 30;
}

void functionB()
{
    int b = 20;
    functionC();
}

void functionA()
{
    int a = 10;
    functionB();
}

int main()
{
    functionA();
    return EXIT_SUCCESS;
}
```

When execution is inside `functionC()`, the call stack looks conceptually like
this:

```text
        Call Stack
    +------------------+
    | Frame 0          |
    | functionC()      |
    | local: c = 30    |
    +------------------+
    | Frame 1          |
    | functionB()      |
    | local: b = 20    |
    +------------------+
    | Frame 2          |
    | functionA()      |
    | local: a = 10    |
    +------------------+
    | Frame 3          |
    | main()           |
    +------------------+
```

- `Frame 0`: Currently executing function.
- `Frame 1`: Function that called frame 0.
- `Frame 2`: Function that called frame 1.
- `Frame 3`: `main()`.

### 6.2 Inspect the call stack

Use:

```text
(gdb) backtrace
```

Example output:

```text
#0  functionC() at example.c:5
#1  functionB() at example.c:11
#2  functionA() at example.c:17
#3  main() at example.c:22
```

Each numbered entry represents a stack frame.

### 6.3 Switch between stack frames

Select `functionC()`:

```text
(gdb) frame 0
```

Select `functionB()`:

```text
(gdb) frame 1
```

Select `functionA()`:

```text
(gdb) frame 2
```

Select `main()`:

```text
(gdb) frame 3
```

### 6.4 Inspect local variables

You can inspect variables belonging to the currently selected frame:

```text
(gdb) frame 1
(gdb) info locals
```

Expected output:

```text
b = 20
```

You can also inspect function arguments:

```text
(gdb) info args
```

### 6.5 Important note

> **Important:** Selecting a frame does not resume execution or change the
> program counter. It only changes the context GDB uses to inspect variables and
> the call stack.

### 6.6 Difference between threads and frames

- A thread represents an execution flow and is selected with `thread N`.
- A frame represents one function invocation within that execution flow and is
  selected with `frame N`.
- `info threads` lists the available threads.

## 7. Text User Interface (TUI)

GDB provides a terminal-based Text User Interface (TUI). TUI allows you to
display source code, assembly instructions, and debugging information directly
in the terminal.

Enable TUI:

```text
(gdb) tui enable
```

Disable TUI and return to the normal terminal interface:

```text
(gdb) tui disable
```

### 7.1 Switch between layouts

```text
(gdb) layout next
```

Switches to the next available TUI layout.

```text
(gdb) layout prev
```

Switches to the previous layout.

### 7.2 Available layouts

- `layout src`: Display source code.
- `layout asm`: Display assembly instructions.
- `layout split`: Display source code and assembly simultaneously.
- `layout regs`: Display register information, where supported.
- `layout next` / `layout prev`: Cycle through the available layouts.

### 7.3 Refresh the TUI

Redraw the TUI display, for example after the terminal has been resized or
corrupted:

```text
(gdb) refresh
```

### 7.4 Example

To display source code while debugging:

```text
(gdb) break main
(gdb) run
(gdb) layout src
```

To display source code and assembly instructions simultaneously:

```text
(gdb) layout split
```

### 7.5 Important notes

- TUI is a standard GDB feature.
- `layout next` and `layout prev` cycle through the available layouts.
- TUI does not change program execution or debugging context.
- Some layouts and register displays may be limited depending on the GDB build.

> **Recommendation:** Use `layout src` or `layout split` when stepping through
> code. They make it easier to follow source code and the corresponding assembly
> instructions.

## 8. Exit the debugger

When finished:

```text
(gdb) quit
```

If the program is still running, use `kill` before `quit`.
