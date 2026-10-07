# Track B long unverified process sample

This was a read-only 60-second observation of the normal Track B shell with 5-second sampling. The route and workload were not manually confirmed, so this is diagnostic evidence rather than an acceptance benchmark. Official Discord was not touched.

| Metric | Value |
| --- | ---: |
| Samples | 13 |
| Process count | 8 |
| Summed private working set | 381.16 MiB |
| Summed working set | 778.39 MiB |
| Summed private bytes | 514.44 MiB |
| Renderer PID | 26104 |
| Renderer private working set | 276.59 MiB |
| Renderer CPU median | 0.05% |
| Renderer CPU p95 | 0.107% |

The longer observation keeps idle CPU below the 0.2% median target in this unverified state. Memory remains above the target and varies materially between short samples, so the canonical authenticated route and settle condition are still required before evaluating an optimization.

Raw capture: `artifacts/track-b-long-unverified-sample-20261007.json`.
