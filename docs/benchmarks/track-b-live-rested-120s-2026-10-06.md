# Track B rested live observation: 120 seconds

Status: diagnostic evidence only. The route and workload were not independently verified, so this is not an authenticated same-route acceptance result.

Source: `artifacts/track-b-live-rested-120s-20261006.json`

## Capture

- Requested duration: 120 seconds
- Recorded duration: 127.316 seconds
- Samples: 11
- Interval: 10 seconds
- Process count: 8
- No runtime or application change was made

## Complete-tree results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Total working set | 817.76 MiB | 833.25 MiB |
| Private working set | 389.16 MiB | 408.96 MiB |
| Derived shareable working set | 424.31 MiB | 424.49 MiB |
| Private bytes / commit | 586.84 MiB | 647.00 MiB |
| CPU | 0.160453% | 0.424099% |

## Final per-process private working set

| Role | Private working set | Private bytes |
| --- | ---: | ---: |
| Renderer | 285.01 MiB | 351.18 MiB |
| GPU process | 43.28 MiB | 202.32 MiB |
| Browser | 36.20 MiB | 48.85 MiB |
| Network service | 9.36 MiB | 15.55 MiB |
| Native shell | 6.80 MiB | 11.12 MiB |
| Audio service | 3.00 MiB | 7.80 MiB |
| Storage service | 2.88 MiB | 7.62 MiB |
| Crashpad | 1.26 MiB | 2.84 MiB |

## Decision

The renderer remains the dominant private-resident owner after additional settling. CPU meets the settled-idle median target, but private working set remains above the approximately 250 MiB complete-tree target. Keep the normal shell unchanged and use this observation as the unverified baseline for a future renderer-specific candidate.
