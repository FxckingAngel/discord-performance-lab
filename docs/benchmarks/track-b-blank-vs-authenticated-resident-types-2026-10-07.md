# Track B blank versus authenticated resident-type comparison

This comparison aligns the previously captured blank WebView2 shell and authenticated settled diagnostic by process role. It is attribution evidence only. The captures are from 2026-10-06, use different PIDs, and do not replace the manually verified same-route acceptance benchmark.

Artifact: `artifacts/track-b-blank-vs-authenticated-resident-types-20261007/comparison.json`

## Complete-tree delta

| Category | Blank | Authenticated | Delta |
| --- | ---: | ---: | ---: |
| Resident pages | 373.61 MiB | 870.03 MiB | +496.42 MiB |
| Private writable resident | 55.03 MiB | 422.33 MiB | +367.29 MiB |
| Mapped resident | 29.94 MiB | 66.78 MiB | +36.84 MiB |
| Image resident | 287.19 MiB | 379.01 MiB | +91.82 MiB |

## Role deltas

| Role | Resident delta |
| --- | ---: |
| Renderer | +388.77 MiB |
| GPU process | +50.73 MiB |
| Browser | +22.50 MiB |
| Network service | +9.76 MiB |
| Audio service | +28.01 MiB |
| Native shell | +0.93 MiB |
| Storage service | +1.48 MiB |
| Crashpad | -5.77 MiB |

The private-writable delta is concentrated in the loaded renderer rather than executable pages. This supports prioritizing renderer-created native state, DOM/layout resources, decoded media, compositor allocations, and other Chromium native allocations. It does not identify which of those categories is reclaimable, so no renderer optimization is selected from this comparison alone.
