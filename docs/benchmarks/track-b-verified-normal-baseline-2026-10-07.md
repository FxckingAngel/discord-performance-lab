# Track B Verified normal-shell baseline

This is a clean 30-second read-only process-tree capture from the rebuilt `bin/Verified/KoroneDiscordShell.exe`. The shell was started after the previous Release instance and smoke-test run had exited. The route and workload were not manually verified, so this is not an authenticated acceptance benchmark.

Artifact: `artifacts/track-b-verified-normal-baseline-20261007/process-tree-30s.json`

| Metric | Median or final |
| --- | ---: |
| Process count | 8 |
| Total working set | 846.81 MiB |
| Private working set | 430.88 MiB |
| Private bytes | 600.03 MiB |
| CPU median | 0.101% |
| CPU p95 | 0.203% |
| Renderer private working set | 314.31 MiB |
| GPU private working set | 40.26 MiB |

CPU is close to the 0.2% median target, while private resident memory remains well above the 250 MiB target. The renderer remains the primary owner. No runtime flags, memory trimming, or feature disablement were used.
