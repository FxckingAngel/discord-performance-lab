# Track B elevated WPR capture

Date: 2026-10-06

The elevated helper completed one 20-second read-only system trace using the built-in `CPU.Verbose` and `ResidentSet.Verbose` profiles.

## Capture record

- Output directory: `artifacts/track-b-wpr-elevated-20261006/`
- ETL: `track-b-cpu-resident.etl`
- ETL size: 1,155,530,752 bytes
- `elevated`: `true`
- `started`: `true`
- WPR start code: `0`
- WPR stop code: `0`
- Error: none

The helper stopped the trace in its `finally` path and wrote `capture-status.json`. No Discord files, account state, authentication state, network behavior, or security settings were changed by the capture.

## Interpretation boundary

This proves that the local machine can record the requested WPR session when the helper is elevated. It does not yet provide decoded CPU stacks, context-switch ownership, hard-fault attribution, or resident-set tables. WPA and `wpaexporter.exe` were not available on this machine, so the ETL remains private raw evidence and is not used to select an optimization.

The next ETL step is to decode this trace with an approved WPA-compatible reader, filter events to the Track B root PID and its descendants, and correlate the result with the existing per-PID private-working-set and CDP captures.
