# Track B post-single-instance baseline: 2026-10-06

This is a clean normal-shell observation after adding the single-instance guard. It used one verified root and a separate rooted process-tree capture. It is not a controlled authenticated A/B comparison.

## Conditions

- Build: verified Track B shell with single-instance enforcement
- Root PID: 5160
- Duration: 92.3 seconds
- Samples: 8 at approximately 10-second intervals
- Process tree: 7 processes throughout
- Renderer count: 1 throughout
- Raw local sample: `artifacts/post-single-instance-clean-settled.json`

## Results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 546.63 MiB | 571.39 MiB |
| Private working set | 188.85 MiB | 222.85 MiB |
| Private bytes / commit | 269.18 MiB | 320.53 MiB |
| CPU, all logical processors | 0.032% | 0.032% |
| Handles | 3,655 | not summarized |
| Threads | 195 | not summarized |

## Role ownership

At the summary median, the renderer held 113.24 MiB private working set and 128.54 MiB private bytes. The WebView2 browser process held 45.60 MiB private working set and 58.70 MiB private bytes. The GPU process held 16.03 MiB private working set and 56.78 MiB private bytes.

## Interpretation

The single-instance guard does not add a second process tree, but this clean run's private-byte median is 19.18 MiB above the approximate target. The variation from earlier seven-process baselines shows that authenticated/profile state and settling history materially affect the result. The next optimization comparison must use the same profile, route, duration, and renderer count on both sides; it must not infer a regression or improvement from this run alone.
