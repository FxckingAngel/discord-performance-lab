# Track B media cache A/B result

Date: 2026-10-07  
Capture: `artifacts/track-b-route-transition-cache-ab-20261007`

## Experiment

This diagnostic repeated the same-renderer static → visible-media → static transition. Before the final static navigation, it called the read-only CDP `Network.clearBrowserCache` operation. The operation was isolated to the diagnostic run and was never enabled in production Track B.

## Result

| State | Complete-tree private WS (MiB) | Renderer private WS (MiB) | GPU private WS (MiB) | GPU mapped resident (MiB) | CPU median (%) |
| --- | ---: | ---: | ---: | ---: | ---: |
| Static before | 428.10 | 319.59 | 36.46 | 5.85 | 0.030 |
| Media visible | 517.72 | 384.90 | 60.50 | 19.02 | 1.640 |
| Static after with HTTP cache clear | 461.99 | 342.66 | 44.70 | 5.94 | 0.030 |

The no-cache-clear settled transition measured 440.90 MiB complete-tree private working set and 326.16 MiB renderer private working set at the 60-second static-after checkpoint. Clearing the HTTP cache therefore did not reduce the retained memory; this run was higher by approximately 21.09 MiB tree-wide and 16.50 MiB in the renderer.

GPU mapped resident memory returned to baseline in both runs. The remaining renderer/private-GPU cost is therefore not explained by ordinary HTTP cache residency alone. The extra reload work after cache clearing may itself account for part of the higher result.

## Decision

Reject HTTP-cache clearing as a Track B optimization. It does not reduce the target metric and could increase resource use or network work. Keep the investigation focused on decoded-resource lifetime, compositor/GPU allocations, and frontend state retention.

No production behavior was changed, and visible media remained enabled throughout the experiment.
