# Track B CDP memory boundary

This comparison uses the existing private CDP diagnostics for a blank shell and a loaded Discord diagnostic state. It is not an authenticated same-route acceptance benchmark.

## Loaded diagnostic state

| Signal | Value |
| --- | ---: |
| V8 used heap | 102.49 MiB |
| V8 total heap | 106.86 MiB |
| V8 embedder heap | 26.38 MiB |
| DOM nodes | 6,143 |
| Documents | 14 |
| JavaScript event listeners | 2,224 |
| Image elements | 151 |
| Video elements | 3 |
| Image natural pixels | 2,953,145 |
| Video pixels | 307,200 |
| Canvas pixels | 128,115 |
| Native allocation sample window | 0.88 MiB |

The corresponding blank diagnostic had 8 DOM nodes, 2 documents, no listeners, no image/video/canvas pixels, and approximately 0.5 MiB V8 used heap.

The loaded renderer's private writable resident memory is approximately 285 MiB in the current full-tree classification. The CDP native allocation sample is far too small and short-lived to account for that resident total, so it is retained as a sampled signal only. The remaining memory cannot be labeled JavaScript solely from the V8 figure. The next controlled comparison must isolate static text, media-heavy content, and call states while preserving the per-renderer Windows classifications.
