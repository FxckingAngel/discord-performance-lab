# Track B manual-checkpoint benchmark

Date: 2026-10-06

## Scope

The user confirmed `READY` after the manual checkpoint workflow: Track B was left running for measurement after manual login/navigation preparation. The capture used the existing normal shell, a rooted process tree, 30-second samples, and a 10-minute duration. No UI automation or account data collection was used.

This is the first user-confirmed checkpoint capture. It is not yet the final A/B acceptance result because the exact route/workload and a contemporaneous official Discord capture still need to be paired, and visual/functional parity has not been completed.

## Full-tree result

Twenty samples were collected over 621.6 seconds across seven processes.

| Metric | Median | P95 | Minimum | Maximum |
| --- | ---: | ---: | ---: | ---: |
| Summed working set | 499.59 MiB | 499.79 MiB | 499.18 MiB | 499.83 MiB |
| Private working set | 146.23 MiB | 146.28 MiB | 145.88 MiB | 146.32 MiB |
| Private bytes / commit | 234.43 MiB | 234.54 MiB | 234.34 MiB | 234.58 MiB |
| Shareable working set | 353.36 MiB | 353.51 MiB | 353.09 MiB | 353.51 MiB |
| Total CPU | 0.001% | 0.001% | - | - |
| Process count | 7 | 7 | - | - |
| Handles | 3552 | 3554.05 | - | 3555 |
| Threads | 173 | 175 | - | 175 |

## Role attribution

| Role | Private working set | Private bytes |
| --- | ---: | ---: |
| Browser | 35.46 MiB | 50.57 MiB |
| Renderer | 84.32 MiB | 101.82 MiB |
| GPU process | 14.92 MiB | 58.45 MiB |
| Network service | 7.29 MiB | 13.06 MiB |
| Storage service | 2.91 MiB | 7.64 MiB |
| Crashpad | 1.32 MiB | 2.88 MiB |

This checkpoint clears the numerical design target when private working set is used as the unique/private resident measure: 146.23 MiB is below 250 MiB and 0.001% CPU is below 0.2%. The summed working set also falls just below the 500 MiB minimum level. These numbers do not prove normal Discord functionality, visual parity, or same-route A/B improvement by themselves.

Raw samples and the generated summary remain under `benchmarks/raw/` and are not published.
