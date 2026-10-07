# Track B canonical authenticated baseline

Date: 2026-10-07

This is a five-repetition measurement of the live Track B shell after manual confirmation of one authenticated, static route. The window remained foreground and untouched at 1920x1080 and 60 Hz. No voice, video, screen share, visible GIF, video, or other media activity was intentionally present. The state is valid for diagnosis only; it is not permission to disable production media or other Discord behavior.

The complete process tree was measured for 60 seconds per repetition after a 30-second settle period. The primary resident-memory metric is summed private working set. Total working set, shareable working set, and private bytes remain separate metrics in the raw summaries.

| Repetition | Private working set median (MiB) | Private bytes median (MiB) | CPU median (% of total) | Samples |
| --- | ---: | ---: | ---: | ---: |
| 1 | 499.17 | 1,137.20 | 0.050 | 13 |
| 2 | 439.04 | 762.32 | 0.020 | 13 |
| 3 | 379.89 | 718.70 | 0.020 | 13 |
| 4 | 383.01 | 721.20 | 0.020 | 13 |
| 5 | 386.53 | 723.62 | 0.020 | 13 |

Across repetitions:

- private working set median: 386.53 MiB
- private working set p95/max: 499.17 MiB
- private working set range: 119.28 MiB
- private working set standard deviation: 46.254 MiB
- private bytes median: 723.62 MiB
- private bytes p95/max: 1,137.20 MiB
- CPU median: 0.017%
- CPU p95: 0.050%

Interpretation: settled idle CPU is already within the 0.2% target. Memory variance is too large to accept small optimizations against this run alone. Repetition 1 is a substantial outlier, so the next step is to correlate each repetition with renderer lifetime, route state, allocation-base groups, and CDP-to-renderer PID identity. No renderer behavior was changed.

Raw private artifacts remain local at `artifacts/track-b-canonical-baseline-20261007-verified/`.
