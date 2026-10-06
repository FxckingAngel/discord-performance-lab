# Track B renderer Windows counters: 30 seconds

Status: read-only diagnostic evidence. The route and workload were not independently verified, and the window is too short to serve as a settled acceptance benchmark.

Source: `artifacts/track-b-counters-current-30s-20261006.json`

The capture preserved individual process rows. The renderer was PID 34528 for this run.

## Renderer results

| Counter | Median | P95 |
| --- | ---: | ---: |
| Private working set | 296.60 MiB | 304.28 MiB |
| Private bytes | 346.38 MiB | 347.59 MiB |
| CPU | 0.095% | 0.191% |
| Page faults/sec | 153.14 | 279.70 |
| Disk read bytes/sec | 2.24 KiB | 2.91 KiB |
| Disk write bytes/sec | 80.33 KiB | 153.33 KiB |
| Threads | 36 | 36 |

## Interpretation

The renderer was still faulting and writing during this short observation. That means the current process state cannot be assumed to be fully settled, even though CPU was low. The counters do not identify whether the faults and writes come from Discord application state, browser cache activity, media resources, or normal runtime behavior.

Keep this as supporting evidence for the attribution work. Do not disable caching, force paging, trim the working set, or change renderer behavior based on these counters alone. A longer, manually confirmed static-channel capture is needed before selecting a memory optimization candidate.
