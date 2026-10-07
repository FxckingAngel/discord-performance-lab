# Track B five-repetition automated baseline: 2026-10-07

Status: automated unverified diagnostic. The manual route checkpoint was intentionally skipped, so this run cannot serve as authenticated same-route acceptance evidence. Official Discord was not touched.

Raw artifacts: `artifacts/track-b-canonical-unverified-20261007/`.

The runner used five repetitions with a five-second settle delay and 15-second measurement windows. Every repetition retained eight processes and the same renderer PID (`30988`).

## Repetitions

| Repetition | Complete-tree private working set median | Complete-tree p95 | Renderer private working set median | CPU median | CPU p95 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 407.30 MiB | 410.53 MiB | 299.24 MiB | 0.138% | 0.397% |
| 2 | 402.82 MiB | 406.03 MiB | 295.96 MiB | 0.015% | 0.015% |
| 3 | 400.14 MiB | 400.96 MiB | 293.53 MiB | 0.030% | 0.031% |
| 4 | 402.29 MiB | 410.51 MiB | 296.88 MiB | 0.046% | 0.061% |
| 5 | 399.29 MiB | 400.09 MiB | 294.16 MiB | 0.030% | 0.352% |

The five repetitions cluster around approximately 402 MiB complete-tree private working set and 296 MiB renderer private working set. This is substantially higher than the earlier ~316 MiB stable-window diagnostic. Since the shell build and renderer identity were stable, the difference is evidence of frontend/lifetime or state variance, not proof of an optimization. The exact route and workload remain unknown and must be manually confirmed before the result can be used as an acceptance baseline.

No renderer behavior, media behavior, authentication behavior, network protocol, or security setting was changed.
