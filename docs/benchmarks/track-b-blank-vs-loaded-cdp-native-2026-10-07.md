# Track B blank runtime floor versus loaded diagnostic

Date: 2026-10-07

This compares two controlled diagnostic-only launches using the same wrapper, 60-second settle, 30-second process attribution, CDP collection, and per-PID resident classification. The blank run used `--diagnostic-blank` and `about:blank`; the loaded run used `--diagnostic-authenticated-no-bridges`. Neither route or account workload was independently verified, so this is not an acceptance benchmark.

## Complete-tree comparison

| Metric | Blank | Loaded | Loaded delta |
| --- | ---: | ---: | ---: |
| Private working set median | 69.72 MiB | 416.69 MiB | +346.97 MiB |
| Private working set p95 | 70.06 MiB | 419.18 MiB | +349.12 MiB |
| Private bytes median | 141.41 MiB | 556.15 MiB | +414.74 MiB |
| Private bytes p95 | 141.93 MiB | 654.96 MiB | +513.03 MiB |
| CPU median | 0.01% | 0.15% | +0.14 percentage points |
| CPU p95 | 0.03% | 0.47% | +0.44 percentage points |

Both runs produced seven process-tree samples. The blank run had no audio service because it loaded no Discord content.

## CDP state comparison

| Metric | Blank | Loaded |
| --- | ---: | ---: |
| V8 used heap | 0.50 MiB | 102.45 MiB |
| V8 total heap | 1.00 MiB | 106.85 MiB |
| Documents | 2 | 14 |
| Frames | 1 | 14 |
| DOM nodes | 8 | 6,143 |
| JavaScript listeners | 0 | 2,224 |
| Image elements | 0 | 151 |
| Video elements | 0 | 3 |
| Canvas elements | 0 | 4 |

The loaded Discord state adds approximately 102 MiB of live V8 heap, but the complete private-working-set delta is approximately 347 MiB. This leaves roughly 245 MiB of loaded private resident memory outside the measured live V8 heap. That remainder includes Blink/DOM, decoded resources, compositor/raster state, and other Chromium native allocations; the available sampling profile is not complete enough to divide it further.

## Blank per-process native classification

| Role | Resident | Private writable resident |
| --- | ---: | ---: |
| Browser | 123.14 MiB | 22.16 MiB |
| GPU | 62.19 MiB | 10.34 MiB |
| Native shell | 56.25 MiB | 5.97 MiB |
| Renderer | 50.30 MiB | 7.30 MiB |
| Network service | 40.58 MiB | 4.32 MiB |
| Storage service | 22.40 MiB | 1.43 MiB |
| Crashpad | 16.39 MiB | 0.92 MiB |

The blank renderer private writable resident floor is approximately 7.3 MiB. The loaded diagnostic renderer was approximately 300.7 MiB by the same classification, so the renderer's loaded delta is approximately 293 MiB. This makes Discord-created renderer state the primary target, rather than the shell's fixed renderer floor.

## Decision

The result does not justify changing the architecture or applying a generic browser flag. The next attribution work should isolate Discord-created renderer state into DOM/layout, decoded images and media, compositor surfaces, and other native allocations. V8 should remain a measured category, but it is not the sole explanation for the memory gap.

Raw captures are in `artifacts/track-b-blank-cdp-native-20261007/` and `artifacts/track-b-current-cdp-native-20261007/`.
