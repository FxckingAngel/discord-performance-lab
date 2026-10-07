# Track B live virtual-memory classification

This read-only `VirtualQueryEx` snapshot followed the live eight-process Track B shell rooted at PID 15152. It is an allocation-boundary diagnostic, not a resident-memory total and not an optimization result.

The renderer PID 25336 had 333.99 MiB of private committed memory, including 331.68 MiB classified as writable and 11.93 MiB classified as executable. The same renderer's live process capture measured 283.28 MiB median private working set and 332.45 MiB private bytes. Protection categories overlap for execute-write regions and must not be added together.

The GPU process had 61.27 MiB private committed memory and 96.5 MiB private bytes in the point-in-time snapshot. The native shell had 8.33 MiB private committed memory and 12.55 MiB private bytes.

This confirms that the renderer's large resident footprint corresponds to a large committed private allocation boundary, but it does not identify which part is Discord state, Blink, media, compositor memory, code, or allocator reserve. No renderer change, trimming, paging, or runtime switch is justified by this result. The raw capture remains local under the ignored `artifacts/` directory.
