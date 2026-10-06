# Track B CDP trace baseline

Date: 2026-10-06

This is a diagnostic-only Chrome DevTools Protocol trace against a disposable blank Track B profile. It validates the aggregate trace path before attempting an authenticated diagnostic. Raw trace events are discarded by the collector; only sanitized counts and durations are written.

## Capture

- Duration: 5 seconds
- Target: Track B `--diagnostic-blank`
- Received events: 1,435
- Data loss: false
- Memory dump request: accepted
- Raw event payloads: not retained
- Summary artifact: `benchmarks/raw/track-b-cdp-trace-blank-memorydump-fixed-20261006.json`

## Aggregate observations

- `RunTask`: 268 events
- `MemoryDumpManager::InvokeOnMemoryDump`: 70 events
- `periodic_interval`: 13 events
- `ProcessMemoryDump`: 6 events
- `GlobalMemoryDump.Computation`: 13 events
- `UpdateLayoutTree`: 0 events
- `Paint`: 0 events
- `CompositeLayers`: 0 events

The blank profile therefore responds to the memory-infra request and produces process-memory dump activity, while this settled blank capture shows no layout or paint work. Event counts are diagnostic signals only. They do not identify which native allocation owns memory, and this unauthenticated blank profile cannot pass the Track B acceptance gate.

The collector is intentionally limited to 1–60 second diagnostic captures, uses a 16 MiB trace buffer, and writes key/count arrays to avoid case-insensitive JSON key collisions. It is not enabled in the normal shell.
