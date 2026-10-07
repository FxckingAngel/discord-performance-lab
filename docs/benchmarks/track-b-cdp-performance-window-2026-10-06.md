# Track B CDP performance window: 2026-10-06

The diagnostic-only `tools/Probe-TrackBCdpPerformanceWindow.mjs` sampled Chromium `Performance.getMetrics` for 60 seconds using the `threadTicks` time domain. It records numeric deltas only and does not collect page content, scripts, URLs, or stacks.

## Conditions

- Profile: authenticated Track B diagnostic profile
- Duration: 60.1 seconds
- Samples: 12 at approximately five-second intervals
- Time domain: `threadTicks`
- Raw local result: `artifacts/cdp-performance-window-60s.json`

## Results

| Metric | Median delta/sample | P95 delta/sample | Total |
| --- | ---: | ---: | ---: |
| Task duration | 0.166 ms | 12.898 ms | 30.434 ms |
| Script duration | 0 ms | 0.018 ms | 0.039 ms |
| Layout duration | 0 ms | 0 ms | 0 ms |
| Style recalculation duration | 0 ms | 0 ms | 0 ms |
| Other task duration | 0.023 ms | 12.791 ms | 28.870 ms |
| Renderer thread time | 0.180 ms | 12.547 ms | 29.977 ms |
| Renderer process time | 0.381 ms | 93.849 ms | 203.930 ms |

## Interpretation

The inspected renderer spent almost no measured time in JavaScript, layout, or style recalculation during this idle diagnostic window. Most of the measured renderer process time was outside those page-level buckets. This supports the existing attribution result that the remaining renderer allocation and CPU ownership cannot be reduced safely by assuming a JavaScript or layout loop.

The result is diagnostic-only and does not prove the same behavior for media-heavy, voice, video, or screen-sharing workloads. It also does not authorize disabling compositor or hardware-acceleration paths.

Source: [Chrome DevTools Protocol Performance](https://chromedevtools.github.io/devtools-protocol/tot/Performance/)
