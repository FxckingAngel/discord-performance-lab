# Track B live continuation per-PID capture

This was a read-only 60-second capture of the already-running normal Track B shell, rooted at PID 15152. The shell remained responsive and was not restarted. The route, account state, and workload were not independently verified, so this is drift and attribution evidence rather than an authenticated acceptance result.

The capture recorded 13 samples across eight processes at the existing display configuration. Complete-tree private working set was 383.98 MiB median and 385.78 MiB p95. Private bytes were 514.89 MiB median. CPU was 0.033% median and 0.118% p95.

| PID | Role | Private working set median | Private working set p95 | Private bytes median |
| ---: | --- | ---: | ---: | ---: |
| 25336 | renderer | 283.28 MiB | 285.10 MiB | 332.45 MiB |
| 26808 | browser | 38.62 MiB | 38.65 MiB | 47.14 MiB |
| 33472 | GPU process | 35.54 MiB | 35.54 MiB | 89.81 MiB |
| 19924 | network service | 9.59 MiB | 9.63 MiB | 14.64 MiB |
| 15152 | native shell | 8.95 MiB | 8.96 MiB | 12.51 MiB |
| 30464 | audio service | 3.18 MiB | 3.18 MiB | 7.83 MiB |
| 24008 | storage service | 3.11 MiB | 3.11 MiB | 7.67 MiB |
| 36904 | crashpad | 1.71 MiB | 1.71 MiB | 2.84 MiB |

The renderer remains the primary resident-memory target. The capture does not identify which renderer allocation is releasable and therefore does not justify a renderer change, memory trimming, or a Chromium switch. The raw capture and summary remain local under the ignored `artifacts/` directory.
