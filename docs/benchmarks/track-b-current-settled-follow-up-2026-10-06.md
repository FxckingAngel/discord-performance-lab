# Track B current settled follow-up: 2026-10-06

This is a short read-only observation of the already-running verified Track B shell. It updates the current baseline; it is not an authenticated same-route A/B acceptance benchmark.

## Conditions

- Build: verified Track B shell
- Root PID: 22780
- Scenario: current settled follow-up
- Duration: 64.0 seconds
- Samples: 11 at approximately 5-second intervals
- Process tree: 7 processes
- Raw local sample: `artifacts/current-settled-follow-up.json`

## Results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 518.99 MiB | 520.82 MiB |
| Private working set | 162.05 MiB | 162.27 MiB |
| Private bytes / commit | 252.71 MiB | 253.07 MiB |
| CPU, all logical processors | approximately 0.006% | short-window quantization limited |

The tree accumulated 0.0625 CPU seconds between the first and last sample. That is approximately 0.098% of one logical processor, or 0.006% when expressed against the machine's 16 logical processors. Five-second sampling quantized most intervals to zero, so this is a directional idle result rather than a replacement for the longer CPU benchmark.

## Role ownership at the final sample

| Role | Private working set | Private bytes |
| --- | ---: | ---: |
| Renderer | 96.15 MiB | 114.93 MiB |
| WebView2 browser | 29.78 MiB | 41.76 MiB |
| GPU | 14.76 MiB | 58.31 MiB |
| Network service | 7.31 MiB | 13.12 MiB |
| Storage service | 2.83 MiB | 7.57 MiB |
| Crashpad | 1.32 MiB | 2.89 MiB |
| Native shell | 8.06 MiB | 12.21 MiB |

## Interpretation

Private working set remains comfortably below the 250 MiB physical-RAM design target. Private bytes remain approximately 2.71 MiB above that target in this short run, an improvement over the earlier 257.47 MiB post-trace median but not proof that the full accounting target is met. The renderer remains the largest private resident owner, followed by the WebView2 browser and GPU processes.

This observation does not establish visual parity, authenticated workload equivalence, or feature completeness. The raw sample stays local and is not published.
