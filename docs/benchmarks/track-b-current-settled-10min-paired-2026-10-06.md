# Track B paired settled 10-minute benchmark

Date: 2026-10-06  
Build: current `Verified` production shell  
Scenario: same live authenticated shell, unchanged route and window state  
Runs: two consecutive 10-minute observations, 40 samples total

Raw runs:

- `benchmarks/raw/track-b-current-settled-10min-20261006.json`
- `benchmarks/raw/track-b-current-settled-10min-repeat-20261006.json`

Combined summary: `benchmarks/raw/track-b-current-settled-10min-paired-summary-20261006.json`

## Complete process tree

| Metric | Median | p95 | Target | Result |
|---|---:|---:|---:|---|
| Total working set | 517.33 MiB | 523.30 MiB | secondary | informational |
| Private working set | 153.87 MiB | 166.45 MiB | approximately 250 MiB | pass |
| Private bytes / commit | 243.64 MiB | 244.05 MiB | approximately 250 MiB | pass |
| Total CPU | 0.001% | 0.001% | 0.2% | pass |
| Process count | 7 | 7 | no fixed limit | stable |
| Renderer count | 1 | 1 | no fixed limit | stable |

The private-bytes result stayed below 250 MiB in both independent 10-minute runs. This is stronger evidence than the earlier single-run result and does not depend on forced trimming, page-out hints, disabled hardware acceleration, or a restart between samples.

## Role attribution

Combined private-byte medians:

| Role | Private bytes |
|---|---:|
| Renderer | 108.34 MiB |
| GPU process | 58.43 MiB |
| Browser/utility | 40.87 MiB |
| Network service | 13.12 MiB |
| Native shell | 12.38 MiB |
| Storage service | 7.70 MiB |
| Crashpad | 2.89 MiB |

The renderer and GPU remain the largest owners. The benchmark establishes resource stability, not the removability of those allocations.

## Remaining acceptance work

This closes the current resource-stability checkpoint only. Track B still requires behavior-level verification of normal Discord functionality, visual comparison against official Discord Desktop, and a controlled same-route A/B comparison. The authenticated UI checkpoint remains a manual workflow; the inability to inspect a native window through the browser connector is not treated as a Track B blocker.
