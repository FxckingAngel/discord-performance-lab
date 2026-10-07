# Track B WPR heap-snapshot research

Date: 2026-10-07

Microsoft's WPR documentation distinguishes ordinary CPU/resident-set
profiles from heap tracing and heap snapshots:

- The built-in Heap usage profile records heap allocations and deallocations
  for a specified process.
- `wpr -HeapTracingConfig <process name> enable` changes heap tracing
  configuration and must be disabled after tracing.
- `wpr -snapshotconfig heap -pid <pid> enable` enables a PID-scoped heap
  snapshot configuration for the lifetime of that process.
- `wpr -singlesnapshot heap <pid>` exports the snapshot allocation information
  into the trace buffer.

Sources:

- https://learn.microsoft.com/en-us/windows-hardware/test/wpt/built-in-recording-profiles
- https://learn.microsoft.com/en-us/windows-hardware/test/wpt/wpr-command-line-options
- https://learn.microsoft.com/en-us/windows-hardware/test/wpt/record-heap-snapshot

## Local verification

The installed WPR supports the heap and snapshot commands. A read-only query
for the current renderer PID reported:

`Heap snapshot is disabled for PID 28160.`

The controlled elevated capture was then run with the existing renderer PID.
It completed successfully with `wpr -snapshotconfig heap -pid 28160 enable`,
`wpr -start HeapSnapshot -filemode`, `wpr -singlesnapshot heap 28160`, and
`wpr -stop`. Cleanup disabled the PID-scoped configuration. The resulting ETL
was decoded with the installed Windows Performance Toolkit using
`xperf -a heapsnapshot -data`.

The decoded result contained one snapshot instance with 18 outstanding
allocations totaling 9,529 bytes. The stacks resolved to Windows loader/TLS,
CRT initialization, and WebView2 worker-thread data. No Chromium private
allocator, Blink, Skia, compositor, WebRTC, or Discord application stack was
present in that snapshot instance. The detailed sanitized result is in
`docs/benchmarks/track-b-wpr-native-ownership-report-2026-10-07.md`.

This proves that the collection and decoding path works, but it does not
explain the renderer's approximately 220 MiB non-V8 remainder. The snapshot
output is not being treated as a complete private-working-set ledger.

## Decision

A PID-scoped WPR heap snapshot remains the correct diagnostic path for the
renderer-native remainder, but it must be an explicit controlled capture. It
can add overhead, produces private allocation evidence, and requires a trace
reader that can resolve the resulting allocation stacks. The reusable helper
is `tools/Invoke-TrackBWprHeapSnapshot.ps1`; it records the ETL privately,
stops and cleans up the PID-scoped configuration, and leaves decoding to
`tools/Decode-TrackBWprHeapSnapshot.ps1`.

The next capture should pair two settled states, static text and media-heavy,
with the same renderer PID where possible. The comparison must retain the
per-PID private working set and the three anonymous region groups beside the
decoded stack families. No renderer behavior should change until those
groups have an evidence-backed owner.

The current shell session is not elevated, so no additional live capture was
started during the follow-up verification. The known-good shell remained
running and responsive.
