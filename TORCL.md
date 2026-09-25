# TorCL port status

This fork is an in-progress native port, not yet a loadable Bordeaux Threads
implementation on TorCL. Its ASDF feature guard deliberately still rejects
TorCL; the backend files are not selected until the complete port is verified.

The `apiv1/impl-torcl.lisp` and `apiv2/impl-torcl.lisp` files provide native
mutex, recursive-lock, and condition-variable adapters. They delegate to
`TORCL-THREAD`, including real contention, timeout, and wakeup handling.
They do not implement no-op synchronization, replace the portable dynamic
binding wrapper, or weaken weak-table semantics.

`test/torcl-native.lisp` exercises the upstream v1 API files and v2 native
SPI using actual TorCL threads. Load it with Alexandria and global-vars
available through ASDF. This focused test does not load the full system;
passing it does not establish complete thread or timeout support. Existing
non-TorCL system selection is unchanged.

`test/torcl-wrappers.lisp` adds the upstream v2 CLOS lock wrappers and portable
semaphores: cross-thread accessors and contention, permit accounting, timeouts,
and a notification handshake. `test/torcl-atomics.lisp` includes those tests
and checks atomic counter read/write, CAS results, full 64-bit values, and
concurrent increment/decrement. These focused tests still do not load the full
ASDF system.

TorCL atomic integers use the same per-counter native-mutex fallback as CLISP.
All counter operations acquire that mutex; they are synchronized, not lock-free.
The internal general atomic-place macros remain unsupported on TorCL.
The focused counter test requires TorCL commit `36acad6` or later (shared CLOS
and macro definitions, full-word byte-type membership, and worker-safe macro
GC roots). Load it with Alexandria and global-vars registered in ASDF:

```lisp
(load "test/torcl-atomics.lisp")
```

The counter test passes under default tiering and under TorCL's moving-GC
stress mode. The former intermittent constructor failure was caused by
thread-local macro roots and is fixed by TorCL `36acad6`; ten consecutive
default-tier runs passed when this requirement was recorded. This validates
the mutex-backed counter implementation, not the still-incomplete full system.

Integration work is tracked in the TorCL repository's Beads issues
`bliss-59qu` and `bliss-1wz7`; global definitions and named FASL dispatch are
tracked in `bliss-nubv` and `bliss-4tkp`. Wrapper/semaphore and atomic counter
validation are tracked in `bliss-aen0` and `bliss-0ext`.
