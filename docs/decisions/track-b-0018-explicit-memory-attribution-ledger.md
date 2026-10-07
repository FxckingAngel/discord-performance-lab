# Decision 0018: distinguish measured and unmeasured memory categories

## Decision

The Phase 2 memory-bucket report now emits an explicit attribution ledger for V8, Blink/DOM/layout, image/GIF/media, Chromium native, GPU/shared textures, and WebRTC/audio/video. Each category carries a status such as `measured`, `sampled-only`, `process-boundary-only`, or `not-measured`.

## Reason

The renderer residual cannot be called JavaScript, media, GPU, or Blink memory without direct evidence. The ledger keeps the requested categories visible while preventing sampled stack bytes or whole-process memory from being mistaken for total category ownership.

## Verification

The performance-tool suite passes. A local authenticated diagnostic reported 110.912 MiB measured V8 heap, 42.36 MiB of GPU-process private working set as a process-boundary value, and no direct byte total for the other categories. No runtime behavior was changed.
