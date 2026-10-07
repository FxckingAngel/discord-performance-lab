# Track B same-renderer media transition with long return settle

Date: 2026-10-07  
Capture: `artifacts/track-b-route-transition-long-return-20261007b`

## Results

The same authenticated renderer was measured in a static state, a visible-image DM, and the same static state after a three-minute return settle.

| State | Complete-tree private WS (MiB) | Renderer private WS (MiB) | GPU private WS (MiB) | CPU median (%) | V8 used (MiB) | Images / visible | DOM nodes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Static before | 410.77 | 302.31 | 37.85 | 0.050 | 106.50 | 131 / 131 | 4,445 |
| Media visible | 481.39 | 353.24 | 58.36 | 1.563 | 104.20 | 203 / 158 | 5,396 |
| Static after 3m | 412.85 | 301.97 | 46.09 | 0.099 | 98.77 | 133 / 133 | 4,497 |

Media added approximately 70.62 MiB to the complete-tree private resident median, 50.93 MiB to the renderer, and 20.51 MiB to the GPU. CPU returned close to idle after the route transition.

After three minutes on the static route, renderer private resident memory was within 0.34 MiB of the initial measurement. The GPU remained 8.24 MiB above the initial measurement. Image and DOM counts also returned close to their starting values.

## Allocation-family transition

The same allocation-base families were tracked within the renderer lifetime. Their sizes changed during media use and moved back toward their original values after the return settle:

| Family | Static before | Media visible | Static after 3m |
| --- | ---: | ---: | ---: |
| Family A | 69.50 MiB | 41.86 MiB | 52.02 MiB |
| Family B | 24.51 MiB | 66.02 MiB | 29.29 MiB |
| Family C | 15.83 MiB | 22.25 MiB | 15.83 MiB |

Family B expanded by about 41.51 MiB during media use and retained only about 4.78 MiB above its original resident size after three minutes. Family A moved in the opposite direction, so the families cannot be interpreted independently as named subsystems. The evidence is consistent with allocator reuse and media/compositor resource movement, but it does not prove ownership.

## Engineering consequence

This is the first repeatable, functionality-preserving workload delta that returns almost completely in the renderer without forced trimming or garbage-collection manipulation. The first optimization investigation should therefore focus on media resource lifetime and GPU/compositor release behavior, while preserving visible image quality and animation.

No production behavior was changed. The result is still not an optimization or a final acceptance benchmark; it is the attribution basis for a reversible media-resource A/B experiment.
