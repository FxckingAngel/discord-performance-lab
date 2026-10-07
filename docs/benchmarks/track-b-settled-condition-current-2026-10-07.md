# Track B settle-condition current observation: 2026-10-07

Status: stable-window diagnostic, not an acceptance benchmark. The exact Discord route and workload were not manually verified. Official Discord was not touched.

Raw artifacts: `artifacts/track-b-settled-current-20261007/`.

The settle runner required three consecutive probe samples with unchanged process identity, process count, window handle, visibility/minimized state, and renderer/GPU private-working-set variation within 2%. It found a stable window after 11 probes, then measured seven samples over 30 seconds.

## Measurement

| Metric | Median | p95 |
| --- | ---: | ---: |
| Complete-tree private working set | 315.80 MiB | 351.06 MiB |
| Renderer private working set | 235.90 MiB | not separately summarized here |
| GPU private working set | 30.53 MiB | not separately summarized here |
| CPU | 0.016% | 0.137% |
| Process count | 8 | 8 |

The window was visible, not minimized, responding, and on the 1920 x 1080 / 60 Hz display. CPU is below the idle target in this run. The complete-tree median remains above the approximately 250 MiB target, and the p95 is materially higher than the median. Because the route/workload was not verified, this is evidence that settle-state variance can be reduced by a stability gate, not evidence that the production target has been achieved.

No renderer behavior, media behavior, authentication behavior, network protocol, or security setting was changed.
