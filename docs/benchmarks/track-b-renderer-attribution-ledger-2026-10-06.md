# Track B renderer attribution ledger

Date: 2026-10-06

Source capture: `artifacts/track-b-cdp-module-current-20261006/`

This is an unverified-route-and-workload diagnostic. It is not an acceptance result and does not represent a settled 10-minute benchmark.

## Renderer resident versus runtime counters

| Measurement | Result |
|---|---:|
| Renderer private working set median | 474.45 MiB |
| Renderer private working set p95 | 510.40 MiB |
| Renderer total working set median | 582.35 MiB |
| Renderer private bytes median | 524.23 MiB |
| V8 used heap | 61.32 MiB |
| V8 total heap | 71.41 MiB |
| V8 embedder heap | 10.29 MiB |
| V8 backing storage | 18.50 MiB |
| DOM documents | 18 |
| DOM nodes | 1,683 |
| JavaScript event listeners | 1,012 |
| Frames | 2 |
| Image elements | 1 |
| Canvas elements | 2 |
| Canvas pixels | 1,040,640 |

The V8 used heap is substantially smaller than the renderer private working set in this capture. The renderer's private resident footprint therefore cannot be called JavaScript memory. The remaining resident categories still require attribution through renderer-native and graphics diagnostics.

## Native sampled allocation signal

| Category | Sampled allocation | Samples |
|---|---:|---:|
| Chromium-native | 29.426 MiB | 821 |
| GPU graphics | less than 0.001 MiB | 3 |
| Total sampled | 29.427 MiB | 824 |
| Profile-attributed total | 47.438 MiB | n/a |

The module-level aggregate maps all sampled allocations to the sanitized `msedge.dll.pdb` label. These are allocation samples over the CDP window. They are not resident bytes and must not be subtracted from the 474.45 MiB renderer private working set.

## Engineering conclusion

This ledger rules out treating the full renderer footprint as V8 heap. It does not yet identify the missing resident categories, so no renderer optimization is approved from this capture. The next measurement should repeat the ledger after a true settled observation and add separate image/media, compositor, and virtual-memory evidence before changing renderer behavior.
