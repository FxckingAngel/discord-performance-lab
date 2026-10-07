# Track B CDP trace checkpoint workflow

Date: 2026-10-06

`tools/Invoke-TrackBCdpTraceCheckpoint.ps1` provides the missing manual visual-state step for authenticated CDP traces.

The workflow:

1. Refuses to start if a normal Track B shell is already running.
2. Starts the diagnostic authenticated profile on the local-only CDP endpoint.
3. Asks the operator to log in, navigate to the requested channel or DM, and leave the intended window state visible.
4. Requires the literal `READY` confirmation before tracing.
5. Runs the aggregate-only CDP trace for the requested duration.
6. Closes the diagnostic process through its normal window action and starts the normal shell again.

The trace output contains only sanitized event counts and durations. The workflow does not automate login, read account data, record screenshots, modify Discord requests, or expose a native capability that the shell does not implement. A missing or non-exact checkpoint confirmation prevents the trace from starting.

This workflow is a measurement aid. It does not by itself establish visual parity, feature completeness, or success against the 250 MiB and 0.2% targets.
