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
The focused counter test requires TorCL commit `93f1af5` or later (shared CLOS
definitions and full-word byte-type membership). Load it with Alexandria and
global-vars registered in ASDF:

```lisp
(load "test/torcl-atomics.lisp")
```

For now, run the counter test with `TORCL_FORCE_TIER=t0`. Default tiering
intermittently fails in the counter constructor with an invalid destructuring
pattern, including on TorCL `93f1af5` (runtime issue `bliss-ozdg`). A single
successful default-tier run does not establish support. The T0 test verifies
the mutex-backed counter implementation; it is not a workaround that makes the
full system ready for normal use.

Integration work is tracked in the TorCL repository's Beads issues
`bliss-59qu` and `bliss-1wz7`; global definitions and named FASL dispatch are
tracked in `bliss-nubv` and `bliss-4tkp`. Wrapper/semaphore and atomic counter
validation are tracked in `bliss-aen0` and `bliss-0ext`.
