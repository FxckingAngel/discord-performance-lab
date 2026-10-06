# Track B synchronized renderer attribution, current diagnostic profile

Date: 2026-10-06

The ordinary shell was closed through its normal window path. The existing private WebView2 profile was then opened in the diagnostic-only no-bridge mode, and the Windows process sampler and loopback CDP diagnostics ran concurrently for the same launch. The diagnostic was closed normally afterward and the ordinary shell was restored. No page input, authentication, protocol, account, or security state was changed.

The route and workload were not independently verified, so this is attribution evidence rather than an authenticated acceptance benchmark.

## Process tree

| Metric | Median | P95 |
| --- | ---: | ---: |
| Processes | 8 | 8 |
| Private working set | 459.43 MiB | 627.37 MiB |
| Private bytes | 618.84 MiB | not used for acceptance here |
| CPU | 0.117% | 0.851% |
| Renderer private working set | 342.96 MiB | not reported in this table |
| Renderer private bytes | 385.57 MiB | not reported in this table |

## CDP aggregate state

| Category | Result |
| --- | ---: |
| V8 used heap | 110.91 MiB |
| V8 total heap | 193.99 MiB |
| V8 embedder heap | 38.86 MiB |
| Array-buffer backing storage | 26.97 MiB |
| DOM nodes | 4,574 |
| Frames | 2 |
| JavaScript event listeners | 2,407 |
| Image elements | 151 |
| Video elements | 3 |
| Canvas elements | 4 |
| Active RTC peer connections | 0 |

## Attribution boundary

The renderer's private working set exceeded measured V8 used heap by approximately 232.05 MiB. This is a lower-bound remainder, not a claim that the difference is removable. It may include Blink structures, decoded image/media resources, compositor allocations, native Chromium allocations, code and allocator space, and retained Discord state. The CDP result does not provide byte-level ownership for those categories.

The 60-second CDP performance window reported 13 documents, 13 frames, 6,093 nodes, 2,407 JavaScript listeners, 3,669 layout objects, 2 workers, 66 ArrayBuffer contents, and zero active RTC peer connections. It recorded zero script, layout, style-recalculation, and task duration at the sampled resolution. The native allocation-category window returned no samples, so it cannot distinguish Blink, image/media, GPU, WebRTC, or other Chromium-native bytes in this run. The empty native profile is an unavailable diagnostic result, not evidence that those categories consume no memory.

This result does not justify forced garbage collection, working-set trimming, disabling hardware acceleration, or discarding Discord state. The next valid implementation candidate still requires a controlled static-versus-media comparison or a supported Chromium native-memory profile that identifies a safe lifetime boundary.

Raw Windows capture: `artifacts/track-b-current-authenticated-no-bridges-60s.json`.
Raw CDP aggregate: `artifacts/track-b-current-authenticated-no-bridges-cdp-60s.json`.
Sanitized Windows summary: `artifacts/track-b-current-authenticated-no-bridges-60s-summary.json`.
