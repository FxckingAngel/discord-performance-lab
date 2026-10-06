# Track B decision 0019: preserve both CDP native-sampling read paths

Date: 2026-10-06

## Decision

The CDP diagnostic now reads `Memory.getSamplingProfile` after a `Memory.startSampling` window and also retains the result of `Memory.stopSampling`. The explicit `getSamplingProfile` result is preferred when available; the stop result remains available for comparison.

An empty profile is reported as `no-samples`, not as zero native allocation. The diagnostic remains local and read-only.

## Why

The Chrome DevTools Protocol defines `Memory.getSamplingProfile` as the profile collected since the last `Memory.startSampling` call. The previous diagnostic only inspected the stop response, so an empty stop response could not distinguish an unsupported or empty window from a readback issue. This change improves attribution evidence without changing the normal shell.

The result is still a sampled allocation profile, not a resident-memory total. It cannot be subtracted directly from private working set or used alone to select an optimization.

## Sources

- [Chrome DevTools Protocol Memory domain](https://chromedevtools.github.io/devtools-protocol/tot/Memory/)
- [WebView2 performance best practices](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/performance)
