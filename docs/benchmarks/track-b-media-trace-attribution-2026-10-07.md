# Track B media trace attribution

Date: 2026-10-07  
Capture: `artifacts/track-b-route-transition-trace-smoke-20261007b`

## Trace quality

The synchronized transition harness captured a sanitized CDP trace at each checkpoint. The trace buffer was increased to 64 MiB after an earlier media trace reported data loss. All three traces in this capture completed with `dataLossOccurred: false`.

Raw trace events were not retained in the artifact. Only aggregate event counts and selected durations are written.

## Aggregate event counts

Each checkpoint used a 15-second trace window after a 10-second settle period.

| State | Received events | RunTask | Layout | Paint | CompositeLayers | Data loss |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Static before | 6,622 | 900 | 1 | 1 | 0 | no |
| Media visible | 396,463 | 41,685 | 4 | 1,070 | 0 | no |
| Static after | 5,696 | 897 | 2 | 5 | 0 | no |

The media checkpoint therefore generated about 46 times as many `RunTask` events and 1,070 paint events as the static checkpoint. After returning to static, both measures returned close to their initial values.

## Interpretation

The trace confirms that the memory and CPU increase during the media route coincides with active rendering/media work. The return to static removes almost all of that task and paint activity, matching the observed renderer and CPU decay.

This does not assign bytes to a specific cache, Skia surface, compositor resource, or Discord component. The trace also did not produce a usable byte-level memory-dump category total in this run. The current evidence supports investigating media decode and rendering-resource lifetime while keeping the normal visible media path intact.

No production behavior was changed, and the trace mode remains diagnostic-only.
