# Track B native allocation sampling: 2026-10-06

Status: aggregate diagnostic evidence only. The route and workload were not independently verified. Sampled bytes are allocation-sampling signals, not resident-memory totals.

Source: `artifacts/track-b-cdp-current-20261006-1656/cdp.json`

## Renderer signals

| Signal | Value |
| --- | ---: |
| Renderer private working set, final process sample | 310.32 MiB |
| V8 used heap | 61.22 MiB |
| V8 total heap | 71.91 MiB |
| Native allocation samples | 690 |
| Native sampled bytes | 27.35 MiB |
| Native attributed bytes | 41.73 MiB |
| Maximum native stack depth | 150 |
| Mapped native frames | 23,031 |

## Sampled categories

| Category | Sampled bytes | Samples |
| --- | ---: | ---: |
| Chromium native | 27.35 MiB | 688 |
| GPU graphics | 96 bytes | 2 |

No sampled media/WebRTC category appeared in this window. The sampled GPU value is negligible compared with the renderer's private working set and does not support a GPU-allocation optimization as the next target.

## Interpretation

The live V8 heap and sampled native allocations account for different diagnostic boundaries and must not be added or subtracted from private working set as if they were resident buckets. Together they do show that the renderer's large remainder is not explained by sampled JavaScript heap or sampled GPU allocations. The next attribution boundary is Chromium-native/Blink/runtime state, which requires a stronger native diagnostic or a controlled frontend state comparison before any change is selected.

No renderer, frontend, GPU, cache, protocol, authentication, or security behavior was changed.
