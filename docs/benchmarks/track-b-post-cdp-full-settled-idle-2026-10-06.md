# Track B post-CDP full settled idle baseline: 2026-10-06

This is a full settled read-only capture after the CDP attribution work and single-instance guard. It used exactly one normal Track B root. No diagnostic CDP endpoint or Chromium launch flag was enabled for the measured shell.

## Conditions

- Build: verified Track B shell
- Root PID: 10900
- Duration: 621.4 seconds
- Samples: 20 at approximately 30-second intervals
- Process tree: 7 processes throughout
- Renderer count: 1 throughout
- Raw local sample: `artifacts/post-cdp-full-settled-idle.json`

## Results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 534.00 MiB | 547.80 MiB |
| Private working set | 181.04 MiB | 194.31 MiB |
| Private bytes / commit | 257.78 MiB | 272.99 MiB |
| CPU, all logical processors | 0.007% | 0.007% |
| Handles | 3,565.5 | 3,622.1 |
| Threads | 177 | 190 |

## Acceptance interpretation

The long-run private-working-set result is below the approximate 250 MiB physical-resident target and the CPU result is well below 0.2%. Private bytes remain approximately 7.78 MiB above the design target, so the stricter commit/private-bytes interpretation is not yet met. The result is not a complete Track B acceptance result because authenticated same-route equivalence, visual parity, and the normal-functionality matrix remain open.

This run establishes a stable one-renderer baseline after the diagnostic changes. It does not justify disabling renderer isolation, forcing garbage collection, trimming working sets, or changing WebView2 security behavior.
