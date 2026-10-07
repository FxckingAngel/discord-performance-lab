# Track B current authenticated attribution

This was a read-only 60-second diagnostic capture after a 60-second settle in the authenticated no-bridge profile. The route and workload were not manually confirmed, so it is attribution evidence only and not acceptance evidence.

| Metric | Median | p95 |
| --- | ---: | ---: |
| Complete-tree private working set | 393.47 MiB | 423.96 MiB |
| Complete-tree total working set | 813.96 MiB | 842.40 MiB |
| Derived shareable working set | 418.62 MiB | 420.49 MiB |
| Complete-tree private bytes | 551.38 MiB | 561.98 MiB |
| CPU | 0.050% | 0.566% |
| Process count | 8 | 8 |

The renderer remained the largest private-resident owner at 279.71 MiB median private working set, followed by the browser at 41.16 MiB, GPU at 37.36 MiB, native shell at 9.82 MiB, and network service at 10.80 MiB. CDP reported 102,797,888 bytes of V8 heap used and 23,782,877 bytes of backing storage. The renderer therefore retains a large non-V8 resident remainder, but this capture does not identify a safe reclaimable owner.

The display was 1920x1080 at 60 Hz. The renderer PID remained stable across all 13 samples, and the WebView2 inventory was captured for correlation. Raw process and CDP data remain private under `artifacts/track-b-current-lifecycle-attribution-20261007/`.
