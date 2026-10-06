# Track B minimized background settled run: 2026-10-06

This run measured the normal Track B shell after its window was minimized. Hardware acceleration, WebView2 security, Discord behavior, and the process model were unchanged.

## Conditions

- Build: verified Track B shell
- Root PID: 34808
- Window state: minimized
- Duration: 129.8 seconds
- Samples: 12 at approximately 10-second intervals
- Process tree: 7 processes throughout
- Renderer count: 1 throughout
- Raw local sample: `artifacts/minimized-background-settled.json`

## Results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 520.15 MiB | 542.46 MiB |
| Private working set | 170.25 MiB | 206.79 MiB |
| Private bytes / commit | 247.50 MiB | 287.52 MiB |
| CPU, all logical processors | 0.033% | 0.033% |
| Handles | 3,624 | not summarized |
| Threads | 189.5 | not summarized |

## Interpretation

Minimizing the window reduced private bytes below the approximate 250 MiB median target and lowered resident memory compared with the foreground run. CPU did not materially change, so the foreground CPU signal is not explained solely by visible compositor work. This is a workload attribution result, not an accepted optimization: the target requires the normal foreground desktop state, and the minimized run does not establish visual or functional parity.
