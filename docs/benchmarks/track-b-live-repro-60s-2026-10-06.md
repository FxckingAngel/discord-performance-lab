# Track B live reproducibility capture

This was a second read-only capture of the already-running normal Track B shell rooted at PID 15152. It recorded 13 samples over 71.6 seconds without restarting the shell. The route, account state, and workload were not independently verified, so this is reproducibility evidence rather than an acceptance result.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Complete-tree private working set | 390.57 MiB | 394.19 MiB |
| Complete-tree private bytes | 525.53 MiB | not reported in this summary |
| Complete-tree CPU | 0.033% | 0.448% |
| Renderer private working set | 289.32 MiB | not reported in this summary |

The previous live capture measured 383.98 MiB complete-tree private working set and 283.28 MiB renderer private working set. The close repeat confirms that the renderer remains the dominant resident-memory boundary rather than a one-sample spike. It does not identify a safe allocation to release, and no runtime or renderer change was made.
