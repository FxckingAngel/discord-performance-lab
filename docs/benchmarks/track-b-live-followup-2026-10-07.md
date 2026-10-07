# Track B live follow-up: current settled-state observation

This is a read-only observation of the already-running normal Track B shell. It does not claim a fixed authenticated route because the native window was minimized and the route was not independently verified during this capture.

## Conditions

- Root PID: 39116
- Process count: 8
- Display: 1920x1080 at 60 Hz
- Window: responding, minimized
- Samples: 7 over approximately 30 seconds
- Renderer PID: 28160
- No renderer, WebView2, protocol, authentication, or security changes

## Complete tree

| Metric | Median | P95 |
| --- | ---: | ---: |
| Total working set | 575.60 MiB | 576.25 MiB |
| Private working set | 371.99 MiB | 372.67 MiB |
| Shareable working set | 203.58 MiB | 204.21 MiB |
| Private bytes | 728.65 MiB | 729.09 MiB |
| CPU | 0.017% | 0.050% |

## Renderer

| Metric | Median | P95 |
| --- | ---: | ---: |
| Total working set | 358.18 MiB | 358.83 MiB |
| Private working set | 316.22 MiB | 316.89 MiB |
| Shareable working set | 41.94 MiB | 42.58 MiB |
| Private bytes | 470.78 MiB | 471.22 MiB |
| CPU | 0.017% | 0.050% |
| Handles | 718 | 718 |
| Threads | 36 | 36 |

## Interpretation

The observation is approximately 61.81 MiB above the earlier 310.18 MiB complete-tree private-working-set sample and approximately 61.30 MiB higher in the renderer. CPU remains below the 0.2% settled-idle target. This is evidence that route or lifecycle state materially affects the memory result, or that the earlier state had naturally released memory; it is not evidence for a code regression.

The renderer virtual-memory snapshot taken after the observation reported approximately 316.7 MiB private-writable resident and 458.9 MiB committed private-writable memory. Its largest anonymous allocation-base families remain present, but this single snapshot cannot identify ownership. Lifecycle checkpoints are required before selecting an optimization.

Raw process and virtual-memory artifacts remain local under `artifacts/track-b-live-followup-20261007/`.
