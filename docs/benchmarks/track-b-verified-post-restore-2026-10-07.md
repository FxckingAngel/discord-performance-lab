# Track B Verified post-attribution restore check

After the long authenticated diagnostic completed, the normal Verified shell was restored through its normal close and launch path. This is a read-only 30-second process-tree check. The route and workload were not manually verified.

Artifact: `artifacts/track-b-verified-post-restore-20261007/process-tree.json`

| Metric | Median |
| --- | ---: |
| Process count | 8 |
| Total working set | 841.81 MiB |
| Private working set | 425.94 MiB |
| Private bytes | 586.62 MiB |
| Renderer private working set | 318.33 MiB |
| CPU | 0.136% |
| CPU p95 | 0.288% |

The restored shell remained responsive and returned to the same broad range as the clean Verified baseline. No diagnostic bridge, memory trim, runtime flag, or feature disablement was left active.
