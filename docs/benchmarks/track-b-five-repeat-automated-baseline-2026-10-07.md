# Track B five-repeat automated baseline

Date: 2026-10-07  
Mode: authenticated normal shell, automated route-unverified diagnostic  
Raw artifacts: local only under `artifacts/track-b-canonical-baseline-20261007-054231/`

This capture used the already running Track B shell. It did not restart or modify official Discord. The manual route checkpoint was intentionally skipped, so the data cannot serve as final same-route acceptance evidence.

## Summary across five repetitions

| Metric | Median | P95 | Minimum | Maximum | Standard deviation |
| --- | ---: | ---: | ---: | ---: | ---: |
| Complete-tree private working set | 413.03 MiB | 422.57 MiB | 402.79 MiB | 422.57 MiB | 6.998 MiB |
| Complete-tree private bytes | 539.22 MiB | 605.44 MiB | 533.48 MiB | 605.44 MiB | 27.262 MiB |
| Complete-tree CPU median | 0.000% | 0.052% | 0.000% | 0.052% | 0.025% |

All five repetitions reported eight processes. The renderer PID remained 48020, and the WebView2 process inventory matched the process-tree inventory on every repetition.

## Per-repetition values

| Repetition | Tree private WS | Tree private bytes | Tree CPU median | Tree CPU p95 | Renderer private WS |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 414.14 MiB | 539.22 MiB | 0.05% | 0.47% | 308.52 MiB |
| 2 | 422.57 MiB | 605.44 MiB | 0.05% | 1.35% | 312.52 MiB |
| 3 | 413.03 MiB | 539.30 MiB | 0.00% | 0.26% | 306.57 MiB |
| 4 | 405.40 MiB | 533.48 MiB | 0.00% | 0.31% | 298.02 MiB |
| 5 | 402.79 MiB | 537.97 MiB | 0.00% | 1.35% | 294.99 MiB |

## Interpretation

The automated settled state is about 163 MiB above the 250 MiB private-resident target. CPU is already below the idle median target in this capture. Private working-set variation across these five runs is about 19.78 MiB, so a claimed optimization should exceed that noise band and be repeated on the same manually confirmed route.

The authenticated route, visible channel, and workload were not manually confirmed. This report therefore establishes variance and process-inventory stability only. It does not claim desktop parity, normal-functionality acceptance, or an optimization result.

No cache clearing, forced garbage collection, working-set trimming, media disabling, quality reduction, protocol change, or partial desktop bridge activation was used.
