# Track B renderer WPR heap snapshot

Date: 2026-10-07

The bounded PID-scoped heap snapshot completed against renderer PID 28160
while the normal shell remained running.

## Capture

- Profile: `HeapSnapshot.Verbose.File`
- Settle interval: 10 seconds
- Snapshot command: succeeded with exit code 0
- Trace stop: succeeded with exit code 0
- Cleanup: confirmed; PID snapshot configuration is disabled
- ETL: `artifacts/track-b-wpr-heap-snapshot-20261007/track-b-heap-snapshot.etl`
- ETL size: 110,377,813 bytes
- Events processed: 268,651
- Events lost: 0
- Heap-snapshot provider events: five event-100 records and two event-200
  records

The decoded aggregate summary is under
`artifacts/track-b-wpr-heap-snapshot-20261007/tracerpt/`.

The local provider manifest contains no field definitions beyond event IDs
100 and 200. A sanitized provider summary records five event-100 records with
55,028 bytes of hex payload and two event-200 records without a hex payload:
`artifacts/track-b-wpr-heap-snapshot-20261007/tracerpt/provider-summary.json`.

## Interpretation boundary

`tracerpt.exe` exposes the heap-snapshot payload as binary event data. WPA and
WPA Exporter are not installed on this machine, so allocation stacks and byte
ownership were not decoded. The raw ETL and CSV stay local because they may
contain process and allocation details. This capture proves that the
renderer-specific heap snapshot path works; it does not yet identify which
allocator owns the renderer's approximately 220 MiB non-V8 resident
remainder.

The helper that performed the capture automatically disables the PID snapshot
configuration in its cleanup path:
`tools/Invoke-TrackBWprHeapSnapshot.ps1`.
