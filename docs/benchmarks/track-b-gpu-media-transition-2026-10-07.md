# Track B GPU media transition

Date: 2026-10-07  
Capture: `artifacts/track-b-route-transition-gpu-settled-20261007`

## Results

The same-renderer transition harness captured the renderer and GPU process memory maps at each readiness-gated state.

| State | Tree private WS (MiB) | Renderer private WS (MiB) | GPU private WS (MiB) | GPU mapped resident (MiB) | CPU median (%) |
| --- | ---: | ---: | ---: | ---: | ---: |
| Static before | 419.70 | 309.34 | 37.21 | 6.07 | 0.050 |
| Media visible | 495.23 | 358.54 | 67.96 | 19.27 | 1.820 |
| Static after 60s | 440.90 | 326.16 | 46.36 | 6.15 | 0.030 |

Media increased renderer private resident memory by 49.20 MiB and GPU private resident memory by 30.75 MiB. The GPU mapped-resident increase was 13.20 MiB and almost completely disappeared after returning to the static route.

After 60 seconds on the static route:

- GPU mapped resident memory was within 0.08 MiB of the initial state.
- GPU private resident memory remained 8.34 MiB above the initial state.
- Renderer private resident memory remained 16.82 MiB above the initial state.
- CPU returned below the idle target.

The earlier three-minute renderer return capture showed the renderer later returning to within 0.34 MiB of its initial private working set. This indicates that release continues after the first minute.

## Interpretation

The mapped graphics component is short-lived, while a private GPU/renderer component decays more slowly. This is consistent with delayed release or allocator reuse after media navigation. It is not evidence that visible media should be disabled, paused, downscaled, or rendered at lower quality.

The GPU allocation-base families are small and change rank across the transition. The current map therefore identifies lifetime behavior but not a named owner. No production renderer behavior was changed.

## Next experiment

Use the same harness with a controlled post-return observation long enough to capture the full decay curve, then test only a reversible resource-lifetime policy in a diagnostic build. The test must preserve visible media behavior and compare image dimensions, GPU memory, renderer memory, responsiveness, and functional results against the unchanged shell.
