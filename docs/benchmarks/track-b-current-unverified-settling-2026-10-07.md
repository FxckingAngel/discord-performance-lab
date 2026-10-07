# Track B current unverified settling observation

Date: 2026-10-07

This was a read-only 10-minute observation of the existing normal shell after restart. The Discord route, account state, and workload were not independently verified, so this is diagnostic evidence rather than an acceptance benchmark.

## Capture

- Root PID: 35936
- Duration: 622.095 seconds
- Samples: 20 at 30-second intervals
- Process count: 8 throughout
- Raw data: `artifacts/track-b-current-unverified-settling-20261007/process-tree.json`

The helper preserved per-PID rows. Shareable working set is the derived total minus private working set because the ordinary process counters do not expose a native unique shared-page counter.

## Complete-tree results

| Metric | Median | p95 |
| --- | ---: | ---: |
| Total working set | 824.33 MiB | 863.59 MiB |
| Private working set | 410.46 MiB | 439.47 MiB |
| Derived shareable working set | 422.19 MiB | 426.48 MiB |
| Private bytes / commit | 653.72 MiB | 775.48 MiB |
| Total CPU | 0.0888% | 0.4823% |

The first sample has no interval CPU value by design. The remaining 19 samples provide the CPU median and p95 above.

## Final per-process state

| Role | PID | Working set | Private working set | Private bytes | Threads | Handles |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Browser | 5336 | 132.80 MiB | 27.15 MiB | 48.15 MiB | 53 | 1,518 |
| Crashpad | 39296 | 16.17 MiB | 1.24 MiB | 2.83 MiB | 8 | 177 |
| GPU | 15996 | 128.61 MiB | 61.97 MiB | 199.54 MiB | 48 | 719 |
| Native shell | 35936 | 53.40 MiB | 6.04 MiB | 11.70 MiB | 9 | 361 |
| Renderer | 38344 | 402.48 MiB | 302.37 MiB | 364.83 MiB | 35 | 716 |
| Audio service | 38852 | 27.52 MiB | 2.48 MiB | 7.96 MiB | 11 | 242 |
| Network service | 21796 | 47.87 MiB | 6.75 MiB | 14.90 MiB | 20 | 359 |
| Storage service | 4388 | 23.47 MiB | 2.46 MiB | 7.61 MiB | 9 | 185 |

## Interpretation

This unverified run settled at approximately 410 MiB private working set, with the renderer accounting for about 302 MiB and the GPU process about 62 MiB at the final sample. It is materially above the earlier low-memory manual checkpoint, but the route and workload were not verified after restart. The result therefore supports further attribution work, not a regression claim or an optimization acceptance claim.

The renderer remains the primary private-resident target. No working-set trimming, forced paging, forced garbage collection, or renderer modification was used.
