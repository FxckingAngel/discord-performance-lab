# Track B post-diagnostic live reproducibility sample

This was a read-only 64.3-second sample of the restored normal shell. The route, account state, and workload were not independently verified. It is drift evidence, not an acceptance result.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Complete-tree private working set | 410.16 MiB | 414.61 MiB |
| Complete-tree private bytes | 559.42 MiB | 586.92 MiB |
| CPU | 0.067% | 0.507% |

The result did not reproduce the earlier 181.04 MiB private-working-set subgate. This variation means the low settled result is state-dependent and cannot be called an optimization until the same workload is repeated under a controlled checkpoint. The raw per-sample process rows remain private in `artifacts/track-b-live-repro-after-retention-60s.json`.
