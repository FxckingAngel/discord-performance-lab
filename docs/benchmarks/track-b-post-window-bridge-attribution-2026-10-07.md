# Track B post-window-bridge attribution

Date: 2026-10-07  
Artifact: `artifacts/track-b-post-window-20261007`

This was a short read-only process-tree capture after the isolated window-capability test. The normal shell was restored, visible, responsive, and measured at 1920x1080 and 60 Hz. It is not a canonical authenticated workload benchmark.

| Metric | Median | p95 |
| --- | ---: | ---: |
| Complete-tree private working set | 417.44 MiB | 446.39 MiB |
| Complete-tree working set | 811.22 MiB | 847.64 MiB |
| Renderer private working set | 310.62 MiB | 334.89 MiB |
| Renderer private bytes | 353.80 MiB | 384.08 MiB |
| GPU private working set | 36.58 MiB | 38.13 MiB |
| CPU | 0.045% | 0.235% |

The process tree contained eight processes. The renderer remained the largest private-resident process. The window bridge test did not produce evidence of a memory reduction or regression large enough to treat as an optimization result.

The capture is diagnostic only. It does not establish the exact authenticated route or workload and does not justify changing renderer behavior.
