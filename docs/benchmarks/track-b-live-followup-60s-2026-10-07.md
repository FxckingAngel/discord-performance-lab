# Track B live follow-up: 60-second variance band

This read-only capture observed the already-running normal Track B shell. The exact authenticated route and workload were not independently verified, so this is diagnostic evidence rather than an acceptance benchmark.

## Conditions

- Root PID: 39116
- Renderer PID: 28160
- Process count: 8
- Display: 1920x1080 at 60 Hz
- Window: responding and minimized
- Samples: 13 over approximately 60 seconds

## Results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Complete-tree private working set | 371.23 MiB | 388.92 MiB |
| Renderer private working set | 314.97 MiB | 332.32 MiB |
| CPU | 0.034% | 1.122% |

The result confirms that the earlier approximately 310 MiB complete-tree sample is not a stable current baseline. The current state is about 121 MiB above the 250 MiB target at p95, with the renderer accounting for most of the difference. CPU remains below the 0.2% target at the median, but the p95 spike should be retained for later wakeup analysis rather than optimized before memory attribution.

Raw artifacts remain local under `artifacts/track-b-live-followup-60s-20261007/`.
