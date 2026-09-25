# TorCL port status

This fork provides a native Bordeaux Threads implementation on TorCL. Its ASDF
system selects the TorCL backend normally.

The `apiv1/impl-torcl.lisp` and `apiv2/impl-torcl.lisp` files provide native
thread-lifecycle, mutex, recursive-lock, and condition-variable adapters. They
delegate to `TORCL-THREAD`, including retained names, truthful liveness and
enumeration, yielding, joins, real contention, timeout, and wakeup handling.
They do not implement no-op synchronization, replace the portable dynamic
binding wrapper, or weaken weak-table semantics. TorCL's immediate native
thread handles use an explicitly cleaned wrapper registry instead of pretending
that fixnum keys can be weak. Lifecycle support requires
TorCL commit `51f2204` or later; TorCL's current native-thread ABI uses fixnum
handles pending first-class thread descriptors.

`test/torcl-native.lisp` exercises the upstream v1 API files and v2 native
SPI using actual TorCL threads. Load it with Alexandria and global-vars
available through ASDF. This focused test does not establish interruption or
destruction support; those operations are reported through Bordeaux Threads'
`NOT-IMPLEMENTED` API. Existing non-TorCL system selection is unchanged.
`test/torcl-asdf.lisp` covers normal ASDF activation, public v2 lifecycle and
semaphore use, multiple return values, and wrapper-registry cleanup.

`test/torcl-wrappers.lisp` adds the upstream v2 CLOS lock wrappers and portable
semaphores: cross-thread accessors and contention, permit accounting, timeouts,
and a notification handshake. `test/torcl-atomics.lisp` includes those tests
and checks atomic counter read/write, CAS results, full 64-bit values, and
concurrent increment/decrement.

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
the mutex-backed counter implementation.

Integration work is tracked in the TorCL repository's Beads issues
`bliss-59qu` and `bliss-1wz7`; global definitions and named FASL dispatch are
tracked in `bliss-nubv` and `bliss-4tkp`. Wrapper/semaphore, atomic counter,
and lifecycle validation are tracked in `bliss-aen0`, `bliss-0ext`, and
`bliss-94kq`.
