# Track B post-smoke settled observation: 600 seconds

Status: diagnostic evidence only. The route and workload were not independently verified, so this is not authenticated same-route acceptance evidence.

Source: `artifacts/track-b-post-smoke-settled-600s-20261006.json`

## Capture

- Root PID: 25240
- Sampler duration: 606.579 seconds
- Samples: 56
- Interval: 10 seconds
- Process count: 8 throughout the recorded samples
- No runtime flags or application changes were made

## Complete-tree results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Total working set | 831.15 MiB | 843.88 MiB |
| Private working set | 413.88 MiB | 425.56 MiB |
| Derived shareable working set | 420.41 MiB | 429.24 MiB |
| Private bytes / commit | 577.31 MiB | 623.46 MiB |
| CPU | 0.117% | 0.353% |

## Final per-process private working set

| Role | Private working set | Private bytes |
| --- | ---: | ---: |
| Renderer | 287.54 MiB | 360.25 MiB |
| GPU process | 42.66 MiB | 120.86 MiB |
| Browser | 36.43 MiB | 47.39 MiB |
| Network service | 8.86 MiB | 14.60 MiB |
| Native shell | 6.81 MiB | 11.12 MiB |
| Audio service | 3.03 MiB | 7.81 MiB |
| Storage service | 2.95 MiB | 8.66 MiB |
| Crashpad | 1.30 MiB | 2.85 MiB |

## Interpretation

The complete-tree private working set remained well above the approximately 250 MiB target after a full 10-minute observation. The renderer remained the largest owner. CPU met the settled-idle median criterion, while p95 is retained as a separate reported value.

This result is a reproducible memory failure for the post-smoke state rather than a short startup-only spike. No optimization was selected from the measurement alone; the next change still requires a specific renderer allocation hypothesis, a rollback path, and functional validation.
