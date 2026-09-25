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
passing it does not establish complete thread, atomic, semaphore, or timeout
support. Existing non-TorCL system selection is unchanged.

Integration work is tracked in the TorCL repository's Beads issues
`bliss-59qu` and `bliss-1wz7`; global definitions and named FASL dispatch are
tracked in `bliss-nubv` and `bliss-4tkp`.
