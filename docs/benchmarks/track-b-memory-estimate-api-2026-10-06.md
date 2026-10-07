# Track B aggregate memory API probe: 2026-10-06

The authenticated diagnostic profile was queried through loopback CDP using a read-only aggregate probe. The probe did not read page content, URLs, cookies, tokens, scripts, heap objects, or raw attribution.

## Result

| Measurement | Result |
| --- | ---: |
| V8 heap used | 33.9 MiB |
| V8 heap allocated | 63.6 MiB |
| `performance.measureUserAgentSpecificMemory()` | Unsupported |
| Cross-origin memory breakdown | Unavailable |

Raw sanitized artifact: `artifacts/diagnostic-authenticated-memory-estimate-20261006.json`.

The browser-supported aggregate API would have returned a breakdown with implementation-defined memory types, but this Discord/WebView2 page does not expose the method. The result therefore does not identify DOM, Blink, media-cache, or native Chromium ownership. It does confirm that the measured V8 used heap is far smaller than the renderer's approximately 120–130 MiB private-bytes allocation.

The probe is based on the documented [Performance.measureUserAgentSpecificMemory() API](https://developer.mozilla.org/en-US/docs/Web/API/Performance/measureUserAgentSpecificMemory). The API is limited-availability and requires security conditions that were not met by this page.
