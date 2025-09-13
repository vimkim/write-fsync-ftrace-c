# fsync-vs-write Demo

This is a tiny project to demonstrate the difference between:

1. Writing data to a file and closing it (`write_only.c`)
2. Writing data and explicitly calling `fsync()` before closing (`write_fsync.c`)

The goal is to show, with tracing tools like **ftrace**, that `fsync()` travels deeper into the kernel: through the VFS layer, the filesystem’s `->fsync` implementation, and eventually into the block layer to issue flushes. In contrast, a plain `write()` followed by `close()` does not guarantee immediate durability.

---

## Build

```bash
gcc -O2 -Wall -o write_only write_only.c
gcc -O2 -Wall -o write_fsync write_fsync.c
```

---

## Usage

```bash
./write_only   /path/to/output.bin
./write_fsync  /path/to/output.bin
```

Each program writes 16 MiB of data to the given file.
`write_fsync` calls `fsync(fd)` before closing; `write_only` does not.

---

## Tracing with ftrace

1. Prepare a clean buffer:

   ```bash
   sudo -s
   cd /sys/kernel/debug/tracing
   echo 0 > tracing_on
   echo nop > current_tracer
   : > trace
   ```

2. Choose the function-graph tracer and filter interesting functions:

   ```bash
   echo function_graph > current_tracer
   echo __x64_sys_write     >  set_ftrace_filter
   echo __x64_sys_fsync     >> set_ftrace_filter
   echo vfs_fsync_range     >> set_ftrace_filter
   echo ext4_sync_file      >> set_ftrace_filter   # or xfs_file_fsync, etc.
   ```

3. Run a program under trace:

   ```bash
   : > trace
   echo 1 > tracing_on
   ./write_fsync /tmp/test.bin
   echo 0 > tracing_on
   cat trace | less
   ```

   Compare the traces for `write_only` vs `write_fsync`.
   You should see `__x64_sys_fsync → vfs_fsync_range → ext4_sync_file` in the latter.

4. Don’t forget to disable tracing afterward:

   ```bash
   echo 0 > tracing_on
   echo nop > current_tracer
   : > trace
   ```

---

## What to look for

* `write_only`: mostly `__x64_sys_write` calls, no explicit fsync path.
* `write_fsync`: a call chain that includes `__x64_sys_fsync`, `vfs_fsync_range`, and your filesystem’s `*_sync_file` implementation.

For block-level evidence of flushes (`REQ_PREFLUSH`, `FUA`), add tracepoints with `trace-cmd` or `bpftrace`.

---

## Disclaimer

This project is for **educational purposes**. It’s a minimal illustration of durability semantics in Linux filesystems. Actual behavior depends on your filesystem, mount options, and hardware write-back cache.

