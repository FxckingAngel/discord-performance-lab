# Track B media-visible diagnostic

Date: 2026-10-07  
Capture: `artifacts/track-b-media-inspection-20261007`

## Scope

This was an exploratory diagnostic on the isolated authenticated no-bridge shell. The page started on Friends, then was moved through the Track B CDP tab into a DM with a visible full-size image. The process capture spans that transition, so it is not a clean steady-state media benchmark and is not an acceptance result.

The clean official Discord client was not touched. No media, hardware acceleration, cache, or rendering setting was changed.

## Sanitized media evidence

The tab-targeted media probe recorded:

- 173 image elements
- 163 visible images
- 173 complete and decoded images
- maximum intrinsic image width: 1,312 pixels
- maximum intrinsic image height: 2,528 pixels
- 22 images with a quality parameter present in the source URL; URL values were not retained
- device pixel ratio: 1
- viewport: 1,280×768

A local tab-targeted screenshot showed a visible large image in the DM. The screenshot remains private and is not included in public documentation.

## Mixed-transition process result

The 60-second process capture covered the transition into the media-visible DM:

| Metric | Median | p95 |
| --- | ---: | ---: |
| Complete-tree private working set | 504.39 MiB | 666.57 MiB |
| Renderer private working set | 354.61 MiB | 526.42 MiB |
| GPU private working set | 80.24 MiB | 83.21 MiB |
| Complete-tree private bytes | 886.97 MiB | 983.40 MiB |
| CPU | 2.144% | 6.068% |

The final sanitized CDP state remained readiness-valid and reported about 112.01 MiB V8 used heap, 5,058 DOM nodes, and 172 image elements.

For comparison, the three five-minute settled non-media repetitions had a complete-tree private-working-set median of 387.09 MiB and a renderer private-working-set median of 281.21 MiB. The comparison is directional because the media capture includes route-transition samples.

## Interpretation

Visible media is a real workload cost in Track B. Renderer private resident memory rose into the mid-300 MiB range, and GPU private resident memory rose to about 80 MiB. The result does not establish whether the cost is decoded image memory, compositor surfaces, GPU textures, Discord state, or transition work.

It also does not justify disabling or pausing visible media. The next controlled capture must measure a settled media-visible DM after navigation has completed, then return to the same static state and measure contraction in the same renderer lifetime.

## Next step

Repeat the transition with separate before, settled-media, and after-return checkpoints. Preserve per-PID memory, V8, DOM/image counts, GPU memory, and allocation-base families at every checkpoint. Compare the families against the repeated static baseline before selecting any optimization.
