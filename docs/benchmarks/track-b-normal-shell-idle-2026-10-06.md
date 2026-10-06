# Track B normal-shell idle observation

Date: 2026-10-06

## Scope

This was a 60-second observation of the ordinary Track B shell after startup. The shell was responsive and contained seven processes. No login state or authenticated Discord channel was assumed, so this is not the acceptance benchmark.

## Full-tree result

Ten samples were collected at approximately five-second intervals.

| Metric | Median | P95 | Minimum | Maximum |
| --- | ---: | ---: | ---: | ---: |
| Summed working set | 529.02 MiB | 535.01 MiB | 522.99 MiB | 535.01 MiB |
| Private working set | 185.06 MiB | 189.17 MiB | 180.61 MiB | 189.17 MiB |
| Private bytes / commit | 264.54 MiB | 269.23 MiB | 259.39 MiB | 269.23 MiB |
| Shareable working set | 344.11 MiB | 345.84 MiB | 342.08 MiB | 345.84 MiB |
| Total CPU | 0.008% | 0.008% | - | - |
| Process count | 7 | 7 | - | - |

The ordinary summed working-set number is above the 500 MiB minimum, while private working set is below the 250 MiB design target. The difference is primarily shareable resident memory, so both metrics must remain in future reports. This does not establish that an authenticated Discord workload can meet either target.

## Last-sample role breakdown

| Role | Working set | Private working set | Private bytes |
| --- | ---: | ---: | ---: |
| Native shell | 58.0 MiB | 7.7 MiB | 11.2 MiB |
| WebView2 browser | 136.7 MiB | 32.5 MiB | 41.9 MiB |
| Renderer | 180.1 MiB | 109.9 MiB | 123.8 MiB |
| GPU process | 68.1 MiB | 17.3 MiB | 58.5 MiB |
| Network service | 46.4 MiB | 8.3 MiB | 13.5 MiB |
| Storage service | 20.0 MiB | 3.0 MiB | 7.6 MiB |
| Crashpad | 13.7 MiB | 1.9 MiB | 3.1 MiB |

The renderer remains the largest private contributor in this shell observation, followed by the GPU process. This is still a runtime-floor attribution and does not identify the cost of Discord's authenticated frontend.

Raw samples remain under `benchmarks/raw/` and are not published.
