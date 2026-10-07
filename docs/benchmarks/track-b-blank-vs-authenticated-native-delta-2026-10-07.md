# Blank versus authenticated renderer native delta

Date: 2026-10-07

The blank and authenticated captures used the same Track B build and the same read-only Windows resident-memory classifier. The blank profile was separate and unauthenticated. The authenticated source was the Friends-route attribution capture.

| Renderer metric | Blank WebView2 | Authenticated Discord | Delta |
| --- | ---: | ---: | ---: |
| Working set | 115.41 MiB | 481.70 MiB | +366.29 MiB |
| Private-writable resident | 32.35 MiB | 368.43 MiB | +336.08 MiB |
| Private-writable committed | 33.97 MiB | 412.24 MiB | +378.27 MiB |
| Private-writable regions at least 16 MiB | 0 MiB | 113.86 MiB | +113.86 MiB |

The large private-writable allocation families are absent from the blank renderer and appear after Discord loads. This makes them Discord-loaded state rather than an unavoidable blank WebView2 floor. It still does not identify the owner or prove that the memory is reclaimable. The next safe experiment is a lifecycle and route comparison that tracks these families through static and media states.

No renderer behavior, feature, quality setting, or Chromium flag was changed for this comparison. Raw artifacts remain private under `artifacts/track-b-blank-vs-authenticated-20261007/` and `artifacts/track-b-renderer-attribution-20261007/`.
