# Track B current lifecycle follow-up

Date: 2026-10-07  
Build: current Track B shell, root PID 45420  
Duration: approximately 11 seconds of six samples at one-second intervals  
Route/workload: not manually confirmed; diagnostic only  
Display: 1920x1080 at 60 Hz

## Result

The existing shell stayed responsive with eight processes. The same renderer PID 30988 remained alive throughout the capture.

| Metric | Minimum | Average | Maximum |
|---|---:|---:|---:|
| Complete-tree private working set | 342.40 MiB | 346.76 MiB | 355.61 MiB |
| Renderer private working set | 276.87 MiB | 279.98 MiB | 285.82 MiB |
| Settled CPU samples | 0.00% | 0.16% | 0.40% |
| Process count | 8 | 8 | 8 |

The first sample is the process-tree baseline and has no CPU interval. The five interval samples have a median CPU of approximately 0.10%; the short capture is not a replacement for a long idle CPU baseline.

## Interpretation

This capture is lower than the corrected five-run diagnostic reference of approximately 399–407 MiB complete-tree private working set, but it is still well above the approximately 250 MiB target. It is consistent with the earlier five-minute lifecycle capture showing natural resident-memory release while the renderer remains alive.

The route and workload were not manually confirmed, so this is lifecycle evidence rather than an acceptance baseline. No trimming, forced collection, media disabling, scheduling change, or renderer behavior change was used.

The result reinforces the next measurement requirement: repeat one manually confirmed static Discord route at fixed lifecycle checkpoints, then perform normal navigation or media activity and return to that route. Allocation-base groups and CDP target PID must be recorded at each transition.
