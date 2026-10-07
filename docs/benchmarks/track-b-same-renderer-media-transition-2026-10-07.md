# Track B same-renderer media transition

Date: 2026-10-07  
Capture: `artifacts/track-b-route-transition-settled-20261007`

## Scope

This capture used one authenticated Track B renderer lifetime and three readiness-gated states:

1. Friends/static state
2. A DM with visible image media
3. Return to Friends/static state

Each state used a 60-second settle period and a 30-second process capture. The route inputs and raw artifacts remain local. The clean official Discord client was not touched.

## Results

| State | Complete-tree private WS (MiB) | Renderer private WS (MiB) | GPU private WS (MiB) | CPU median (%) | V8 used (MiB) | Images / visible | DOM nodes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Static before | 425.99 | 318.33 | 36.88 | 0.020 | 108.55 | 133 / 133 | 4,480 |
| Media visible | 509.55 | 369.81 | 69.78 | 1.630 | 120.14 | 202 / 157 | 5,489 |
| Static after | 412.35 | 301.05 | 47.50 | 0.050 | 109.04 | 141 / 141 | 4,623 |

The media transition added approximately:

- **83.56 MiB** complete-tree private resident memory
- **51.48 MiB** renderer private resident memory
- **32.90 MiB** GPU private resident memory
- **1.61 percentage points** of median CPU
- **69** image elements and **1,009** DOM nodes at the media checkpoint

After returning to the static state, renderer and tree memory contracted substantially. GPU memory remained about 10.62 MiB above the initial state, and the final image/DOM counts remained slightly higher. This shows partial release rather than a complete return to the original state.

## Allocation-family evidence

The resident map preserved the same allocation-base identities across the three checkpoints because the renderer stayed alive. Two private-writable families were especially informative:

| Family | Static before | Media visible | Static after | Media delta | After-return delta |
| --- | ---: | ---: | ---: | ---: | ---: |
| Family 1 | 69.09 MiB | 72.97 MiB | 47.86 MiB | +3.88 MiB | -21.23 MiB |
| Family 2 | 24.20 MiB | 64.93 MiB | 19.27 MiB | **+40.73 MiB** | -4.93 MiB |
| Family 3 | 17.75 MiB | 11.65 MiB | 15.83 MiB | -6.10 MiB | -1.92 MiB |

Family 2 is the first narrow optimization candidate. It expands by about 40.73 MiB in the visible-media state and releases most of that allocation after returning to the static route. The current evidence does not identify it as a cache, compositor surface, decoded image store, or specific Chromium subsystem, so the family is intentionally left unnamed.

## Interpretation

This is a real workload-dependent native-memory effect, not an incomplete-page measurement or a forced-trimming result. Visible media remained enabled and rendered normally. The evidence supports investigating the ownership and release behavior of Family 2 and the GPU increase, while preserving the normal media path.

The result is not yet an optimization. No renderer behavior was changed, and the static-after state needs a longer post-return observation to determine whether the remaining GPU and image/DOM deltas decay naturally.

## Next step

Repeat this transition with a longer post-return settle and a media-heavy channel containing animated media. Correlate Family 2 with decoded image dimensions, animation/video state, compositor/GPU memory, and native allocation sampling. Only then test a reversible resource-lifetime change such as releasing decoded resources that are no longer visible.
