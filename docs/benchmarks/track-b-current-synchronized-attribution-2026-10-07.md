# Track B current synchronized attribution

Date: 2026-10-07

This capture used the reusable `Invoke-TrackBUnverifiedCurrentAttribution.ps1` harness with the authenticated no-bridge diagnostic shell, a 60-second settle period, a 60-second CDP diagnostic window, and 5-second process samples. The normal shell was restored afterward. The route and workload were not manually confirmed, so this is diagnostic evidence only.

## Complete process tree

| Metric | Median | P95 |
| --- | ---: | ---: |
| Total working set | 827.26 MiB | 839.28 MiB |
| Private working set | 408.76 MiB | 423.76 MiB |
| Shareable working set | 417.27 MiB | 418.50 MiB |
| Private bytes | 555.24 MiB | 598.26 MiB |
| CPU | 0.081% | 0.473% |
| Process count | 8 | 8 |

## Renderer and CDP state

| Metric | Value |
| --- | ---: |
| Renderer private working set | 295.95 MiB median, 306.58 MiB p95 |
| Renderer private bytes | 333.85 MiB median |
| V8 used heap | 104,507,544 bytes, approximately 99.67 MiB |
| V8 heap capacity | 110,211,072 bytes, approximately 105.08 MiB |
| V8 backing storage | 23,987,863 bytes, approximately 22.88 MiB |
| DOM nodes | 5,232 |
| Documents | 10 |
| Frames reported by performance metrics | 10 |
| JavaScript event listeners | 1,477 |
| Layout objects | 3,311 |
| Image elements | 121 |
| Video elements | 0 |
| Canvas elements | 2 |
| Detached script states | 0 |

The renderer therefore retained approximately 196 MiB of private working set beyond the measured V8 used heap. This is a difference between two measurements, not an attribution to Blink, Skia, compositor, media, or WebView2. The remaining categories require further evidence.

The CDP native sampling result attributed one sampled 110,211,072-byte sample to V8 with an unknown module and a maximum stack depth of one. It is not a complete native-memory census and must not be used to label the non-V8 remainder.

## Interpretation and next experiment

The paired process and CDP measurements now share a diagnostic shell and time window, and all eight process roles were classified successfully. The next experiment should hold the exact route constant and compare this state with a manually confirmed static route and a media-heavy route. It should compare renderer private working set, V8 heap, DOM/resource counts, image and media counts, GPU memory, page faults, and allocation-base groups.

No renderer behavior, media behavior, authentication, network behavior, or official Discord installation was changed. Raw process, CDP, and resident-classification artifacts remain private under `artifacts/track-b-current-synchronized-20261007/`.
