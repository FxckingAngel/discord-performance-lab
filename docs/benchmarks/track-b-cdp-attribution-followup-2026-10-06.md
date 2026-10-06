# Track B CDP attribution follow-up

Date: 2026-10-06

This was a diagnostic-only run against the authenticated Track B profile on loopback CDP port 9228. The normal shell was stopped and relaunched into the private diagnostic mode, then returned to the normal shell after collection. The official Discord client was not changed.

The diagnostic wrote aggregate-only local artifacts. No heap objects, page text, URLs, cookies, tokens, stack traces, or heap snapshots were published.

## Renderer heap and document state

| Measurement | Result |
| --- | ---: |
| V8 used heap | 27.7 MiB |
| V8 total heap | 61.1 MiB |
| Embedder heap | 11.9 MiB |
| Backing storage | 16.6 MiB |
| DOM nodes | 974 |
| Frames | 2 |
| Images | 0 |
| Videos | 0 |
| Canvases | 0 |

The aggregate native-memory method returned one approximately 61.1 MiB sample and no stack-frame list. It is retained as an attribution signal only. It is not a complete native-allocation census and is not added to the Windows process private-memory total.

## 60-second idle performance window

The probe collected 12 samples at five-second intervals using the `threadTicks` time domain.

| Metric | Median per sample | P95 per sample | Total |
| --- | ---: | ---: | ---: |
| Task duration | 0.000170 s | 0.000271 s | 0.002040 s |
| Script duration | 0 s | 0 s | 0 s |
| Layout duration | 0 s | 0 s | 0 s |
| Style recalculation | 0 s | 0 s | 0 s |
| Other task duration | 0.000020 s | 0.000142 s | 0.000608 s |
| Renderer thread time | 0.000189 s | 0.000289 s | 0.002296 s |
| Renderer process time | 0.000273 s | 0.000456 s | 0.003379 s |

The result provides no evidence of an idle JavaScript, layout, or style-recalculation loop. The remaining renderer allocation is therefore still primarily unclassified Blink/native/runtime state, and the next optimization must use a measured allocation owner or a controlled architecture comparison. No renderer-isolation change, forced collection, memory trimming, or unmeasured Chromium switch was added.

The diagnostic also queried Chromium's optional `Memory.getBrowserSamplingProfile` method. The method was accepted, but it returned zero samples and zero sampled bytes on this WebView2 build. That is an unsupported/empty diagnostic result, not evidence that the browser process has no native allocations. The renderer `Memory.getAllTimeSamplingProfile` call continued to return one aggregate sample. The sanitized follow-up artifact is local at `artifacts/diagnostic-authenticated-browser-memory-20261006.json`.

Raw artifacts remain private at:

- `artifacts/diagnostic-authenticated-cdp-followup-20261006.json`
- `artifacts/diagnostic-authenticated-cdp-performance-followup-20261006.json`
