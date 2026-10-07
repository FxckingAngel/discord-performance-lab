# Track B Discord frontend floor follow-up

This control launched the verified shell with `--diagnostic-discord` in its separate unauthenticated environment-probe profile. It did not reuse account credentials or authenticated profile data. The diagnostic closed normally and the normal shell remained separate.

## Results

| State | Complete-tree private WS | Renderer private WS | CPU median |
| --- | ---: | ---: | ---: |
| Blank WebView2 control | 71.75 MiB | 9.77 MiB | 0.016% |
| Unauthenticated Discord diagnostic | 330.93 MiB | 233.16 MiB | 0.082% |
| Current authenticated live state | 371.23 MiB | 314.97 MiB | 0.034% |

The unauthenticated Discord diagnostic adds approximately 259.18 MiB complete-tree private working set over the same-build blank control. The current authenticated state adds approximately 40.30 MiB beyond the unauthenticated diagnostic. These are state deltas, not allocator ownership claims. The unauthenticated route and the authenticated route were not the same workload, so this is isolation evidence rather than the final acceptance comparison.

## Interpretation

The runtime floor alone does not explain the Track B gap. Discord's loaded frontend state is the dominant cost, with the renderer owning most of the unauthenticated delta. The next experiment should compare lifecycle and route transitions while preserving per-PID and allocation-base data. No renderer behavior or Chromium flags were changed from this result.

Raw artifacts remain local under `artifacts/track-b-discord-frontend-floor-20261007/`.
