# Track B decision 0012: native allocation sampling stays diagnostic-only

Date: 2026-10-06

## Decision

Use the WebView2-attached Chrome DevTools Protocol as a read-only attribution aid. The Phase 2 CDP diagnostic now records DOM counters, native allocation samples, and V8 sampling totals without writing page content, URLs, cookies, tokens, heap objects, or raw allocation stacks to the public artifact.

The native profile is grouped into coarse categories such as Blink, GPU graphics, media/WebRTC, image/media, network/cache, Chromium native, V8, and other. These categories describe sampled allocation call sites. They are not resident-memory totals and must not be treated as proof that a category can be released.

V8 sampling reports node self-size only. Summing retained subtree totals would count the same descendants repeatedly, so it is not used for the live-heap estimate.

## Why

The current authenticated evidence shows a large renderer private working-set remainder after subtracting V8 live heap. Process counters identify the size of that remainder but not its cause. Read-only CDP sampling can narrow the next investigation without changing Discord's frontend, protocol, authentication, security state, or runtime configuration.

## Limits

- A sampled allocation category is not equivalent to private working set or unique physical RAM.
- CDP availability depends on an explicitly launched diagnostic shell. The normal shell remains the known-good baseline and does not expose a debugging port by default.
- Raw heap snapshots and any future raw profiles remain local under `benchmarks/private/` and are excluded from commits.
- No renderer optimization will be selected from this report alone. A candidate must also show a safe lifetime rule, preserved functionality, and a lower complete-tree private working set.

## Sources

- Chrome DevTools Protocol Memory domain: https://chromedevtools.github.io/devtools-protocol/tot/Memory/
- Chrome DevTools Protocol HeapProfiler domain: https://chromedevtools.github.io/devtools-protocol/tot/HeapProfiler/
- Microsoft WebView2 CDP guidance: https://learn.microsoft.com/en-us/microsoft-edge/webview2/how-to/chromium-devtools-protocol
