# Track B current unverified WPR heap snapshot

Date: 2026-10-07  
Renderer PID: 28160  
Scenario label: current unverified state

## Capture status

The elevated PID-scoped WPR capture completed successfully:

| Operation | Result |
| --- | ---: |
| Snapshot configuration | enabled and cleaned up |
| WPR start | 0 |
| Single heap snapshot | 0 |
| WPR stop | 0 |
| Lost-event check | not reported in the capture status |

The raw ETL remains private at
`artifacts/track-b-wpr-current-unverified-20261007/track-b-heap-snapshot.etl`.

## Sanitized decode

The installed Windows Performance Toolkit decoded one snapshot instance:

| Measure | Value |
| --- | ---: |
| Outstanding allocations | 16 |
| Outstanding bytes | 8,481 bytes |
| Outstanding decoded heap | 0.008088 MiB |

Observed symbolized families were Windows NT heap/loader, FFmpeg, kernel32,
and CRT initialization. No Chromium PartitionAlloc, Blink, Skia, compositor,
WebRTC, or Discord application allocation family appeared.

This is a current renderer capture, but the route and workload were not
manually verified as static text or media-heavy. It is therefore not used as a
scenario comparison or optimization decision. As with the earlier snapshot,
the decoded outstanding set is not a complete renderer private-working-set
ledger and does not explain the native resident remainder.

Sanitized output:

`artifacts/track-b-wpr-current-unverified-20261007/sanitized-xperf-native-ownership.json`
