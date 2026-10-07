# Track B Verified authenticated long-settle attribution

This was a read-only attribution run using the rebuilt Verified executable and the authenticated no-bridge diagnostic profile. It used 120 seconds of settling followed by 60 seconds of sampling. The route and workload were not manually verified, so it is not an acceptance benchmark.

Artifacts: `artifacts/track-b-verified-authenticated-unverified-long-20261007/`

## Settled tail

| Metric | Last-five median |
| --- | ---: |
| Total working set | 838.63 MiB |
| Private working set | 416.68 MiB |
| Private bytes | 572.43 MiB |
| Renderer private working set | 305.43 MiB |
| GPU private working set | 44.16 MiB |

CDP reported 107.17 MiB V8 used heap, 6,286 DOM nodes, 2,366 event listeners, 166 image elements, and 3 video elements. The native allocation sample window was approximately 1.04 MiB and remains a sampled signal, not a resident-memory total.

The last-five tail is close to the earlier loaded-state baselines, while the first short run's higher values fell during settling. This rules out treating the initial spike as the settled target, but it still leaves approximately 305 MiB of renderer private resident memory to explain and reduce. The diagnostic's raw process-tree schema did not provide a usable aggregate CPU series, so CPU is not reported from this run.

The normal Verified shell was restored through its normal close path after capture.
