# Track B authenticated-profile CDP trace

Date: 2026-10-06

This diagnostic used the existing Track B authenticated-profile user-data folder with the diagnostic-only CDP port. The normal shell was closed through its window action before the capture and restored afterward. No authentication, network, security, or Discord state was modified by the collector.

## Capture

- Duration: 10 seconds
- Received events: 3,183
- Data loss: false
- Memory dump request: accepted
- `RunTask`: 436
- `Edge_RunTask`: 1,043
- `ThreadPool_RunTask`: 607
- `BlinkScheduler_PerformMicrotaskCheckpoint`: 14
- `UpdateLayoutTree`: 0
- `Paint`: 0
- `CompositeLayers`: 0
- `ProcessMemoryDump`: 6
- `periodic_interval`: 13

The raw local summary is `benchmarks/raw/track-b-cdp-trace-authenticated-20261006.json`.

## Comparison with the blank diagnostic

The earlier 5-second blank trace produced 1,435 events and 268 `RunTask` events. Normalized by time, the authenticated-profile diagnostic produced fewer `RunTask` events per second, but more total events because of its longer capture. Both traces reported zero layout, paint, and compositor events.

## Interpretation

The trace confirms that the WebView2/CDP memory-infra path works against the authenticated profile and that the profile generates ordinary browser tasks and memory-dump activity. It does not prove that a logged-in Discord channel was visibly rendered. The absence of layout and paint events makes this unsuitable for the authenticated same-route benchmark and visual-parity gate. It is a runtime diagnostic only, not evidence that Discord frontend work is optimized or that Track B functionality is complete.

The next authenticated trace must be taken after a manual checkpoint confirms that the intended route is visibly rendered. Until then, no renderer optimization is selected from these task counts.

`tools/Compare-TrackBCdpTrace.ps1` now normalizes selected event counts and durations per second without reading raw event payloads. A comparison of this profile against the blank baseline is stored locally at `benchmarks/raw/track-b-cdp-trace-blank-vs-auth-20261006.json`; it shows 43.6 `RunTask` events/sec in the profile diagnostic versus 53.6/sec in the blank trace, with zero layout, paint, and compositor events in both. This comparison is diagnostic only because neither capture establishes the intended visible Discord route.
