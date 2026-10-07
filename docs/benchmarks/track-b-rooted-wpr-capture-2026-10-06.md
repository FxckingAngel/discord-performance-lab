# Track B rooted WPR capture

Date: 2026-10-06

A second elevated WPR capture was recorded while the authenticated Track B shell was running. The helper was given the shell root PID and saved the descendant-PID manifest before and after the trace.

## Capture record

- Scenario label: `authenticated-settled`
- Root PID: 28156
- Rooted process count before capture: 8
- ETL: `artifacts/track-b-wpr-rooted-20261006/track-b-cpu-resident.etl`
- WPR start code: `0`
- WPR stop code: `0`
- Elevated: `true`
- Events processed after decoding: 18,714,342
- Events lost: 0
- CPU samples: 278,077
- Stack walks: 6,449,645
- Hard-fault events: 6,919
- Disk reads: 14,411
- Disk writes: 6,011
- Thread-ready events: 1,626,338

The private artifact directory contains `root-process-tree-before.json` and `root-process-tree-after.json`. Those manifests retain local command-line role data for PID mapping and are not copied into public documentation.

The trace itself is still system-wide. The root manifest makes later PID filtering possible, but the aggregate event counts above must not be interpreted as Track B-only counts until an ETL reader extracts and filters event payloads by the recorded PIDs.
