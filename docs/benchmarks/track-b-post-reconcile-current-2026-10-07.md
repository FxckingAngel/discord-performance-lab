# Track B post-reconciliation current sample

This was a read-only 125-second sample of the restored normal Track B shell after the benchmark-policy and desktop-identity reconciliation. The route and workload were not manually confirmed, so it is current-state evidence rather than acceptance evidence.

| Metric | Median | p95 | Min | Max |
| --- | ---: | ---: | ---: | ---: |
| Complete-tree private working set | 378.45 MiB | 384.68 MiB | 200.20 MiB | 384.68 MiB |
| Complete-tree total working set | 787.82 MiB | 793.89 MiB | 466.00 MiB | 793.89 MiB |
| Complete-tree private bytes | 512.57 MiB | 541.67 MiB | 488.80 MiB | 541.67 MiB |
| CPU | 0.045% | 0.702% | not summarized | not summarized |

The tree remained at eight processes. The first sample was still settling, which is why the minimum is materially below the settled median. This result does not establish an optimization or change the approximately 250 MiB idle target.

Raw data remains private under `artifacts/track-b-post-reconcile-current-20261007/`.
