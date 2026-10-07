# Track B WPR tracerpt summary

Date: 2026-10-07

`tracerpt.exe` successfully read the private elevated WPR capture at
`artifacts/track-b-wpr-elevated-20261006/track-b-cpu-resident.etl` and wrote a
summary and report under
`artifacts/track-b-wpr-elevated-20261006/tracerpt-summary-20261007/`.

## Capture-level evidence

- ETL size: 1,155,530,752 bytes
- Buffers processed: 1,102
- Events processed: 10,989,877
- Events lost: 0
- CPU samples: 128,025
- Stack-walk events: 2,021,610
- Hard-fault events: 22,806
- Process start events: 390
- Thread ready events: 541,911
- The report completed with exit code 0.

This confirms that the ETL contains scheduler, sampling, page-fault, process,
and thread data that can be read by a trace reader. These counts are for the
whole captured system, not for Track B alone.

## Interpretation boundary

The available `tracerpt.exe` summary does not attribute events to the Track B
root PID or its descendants, resolve CPU stacks to useful symbols, or produce
resident-memory ownership tables. The ETL and generated report remain private
diagnostic artifacts. They must not be used to choose a renderer optimization
until a PID-filtered trace analysis is available.

The existing per-PID private-working-set, virtual-memory, and CDP measurements
remain the current decoded evidence. The elevated WPR path is now validated as
recordable and partially readable, but it is not a replacement for WPA-level
analysis.
