# write-fsync-ftrace (Linux ftrace demo)

This repo demonstrates a simple but important observation with ftrace: if a program does not call `fsync(2)`, the syscall trace does not show any fsync activity; if it calls `fsync(2)`, the trace clearly captures the fsync path.

There are two tiny programs:
- `write_only.c` — writes 16 MiB and closes (no `fsync`).
- `write_fsync.c` — writes 16 MiB and then calls `fsync(fd)` before close.

Traces are captured using the kernel ftrace interface under `/sys/kernel/debug/tracing`.

---

## Requirements

- Linux with ftrace/tracefs available (`/sys/kernel/debug/tracing`).
- `sudo` privileges to toggle tracing and read the trace buffer.
- `gcc` to build the test binaries.

---

## Build

- With `just` (recommended): `just build`
- Or manually:
  - `gcc -O2 -Wall -o write_only write_only.c`
  - `gcc -O2 -Wall -o write_fsync write_fsync.c`

---

## Capture Traces (via justfile)

- `just trace-write_only`
  - Clears the trace buffer, starts tracing, runs `./write_only write_only.txt`, stops tracing.
  - Saves output to `./trace_write_only.txt`.

- `just trace-write_fsync`
  - Clears the trace buffer, starts tracing, runs `./write_fsync write_fsync.txt`, stops tracing.
  - Saves output to `./trace_write_fsync.txt`.

- `just trace-cat`
  - Prints the current kernel trace buffer to the terminal.

Note: These recipes operate on the live ftrace buffer and expect `sudo` access. Ensure tracefs is mounted (most distros mount it automatically under debugfs).

---

## Results (from this repo)

- `trace_write_only.txt` contains no fsync path — there is no `__x64_sys_fsync` captured because the program never calls `fsync`.

- `trace_write_fsync.txt` shows the fsync syscall and VFS sync path, for example:

  ```
  # tracer: function_graph
  # CPU  DURATION                  FUNCTION CALLS
    1)               |  __x64_sys_fsync() {
    1)               |    vfs_fsync_range() {
    5) * 17318.74 us |    } /* vfs_fsync_range */
    5) * 17322.31 us |  } /* __x64_sys_fsync */
  ```

This directly reflects the key finding: without an explicit `fsync(2)`, the syscall ftrace does not contain fsync; with `fsync(2)`, the trace captures `__x64_sys_fsync → vfs_fsync_range` along with timing.

---

## Tips

- If you want to focus the trace, set the tracer and filters before running the `just` targets, e.g.:
  - `echo function_graph | sudo tee /sys/kernel/debug/tracing/current_tracer`
  - `echo __x64_sys_fsync | sudo tee /sys/kernel/debug/tracing/set_ftrace_filter`
  - `echo vfs_fsync_range | sudo tee -a /sys/kernel/debug/tracing/set_ftrace_filter`
- The exact filesystem-specific sync function (e.g., `ext4_sync_file`, `xfs_file_fsync`) may also appear depending on configuration and filters.

---

## Disclaimer

Behavior can vary by filesystem, mount options, writeback settings, and hardware caches. This is a minimal educational example to contrast `write` vs `write+fsync` as observed by ftrace.
