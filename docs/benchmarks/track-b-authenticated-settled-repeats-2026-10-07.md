# Track B authenticated settled repetitions

Date: 2026-10-07  
Runs: `artifacts/track-b-settled-repeat-{1,2,3}-20261007`  
Mode: authenticated no-bridge diagnostic shell

## Scope

Each run started a fresh Track B diagnostic process, waited five minutes, then measured the complete process tree for 45 seconds at five-second intervals. The normal Track B shell was restored after every run. The clean official Discord client was not touched.

All three CDP captures passed the conservative readiness predicate:

- route class: `discord-channels`
- document complete
- `#app-mount` present and populated
- DOM threshold passed
- 8-process tree
- 1920×1080 display at 60 Hz

These are readiness-gated diagnostic baselines. They are not the final same-route acceptance benchmark because the route was not manually confirmed during each fresh restart.

## Results

| Run | Complete-tree private WS median / p95 (MiB) | Renderer private WS median / p95 (MiB) | Complete-tree private bytes median / p95 (MiB) | CPU median / p95 (%) | Processes |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 387.09 / 395.84 | 279.23 / 282.28 | 533.20 / 606.65 | 0.170 / 0.483 | 8 |
| 2 | 395.53 / 400.49 | 289.03 / 291.78 | 544.00 / 590.30 | 0.084 / 0.650 | 8 |
| 3 | 383.23 / 388.50 | 281.21 / 282.60 | 536.58 / 623.36 | 0.050 / 0.433 | 8 |

Across the three run-level medians:

- complete-tree private working set median: **387.09 MiB**
- complete-tree private working-set range: **383.23–395.53 MiB**
- median of the per-run p95 values: **395.84 MiB**
- renderer private working set median: **281.21 MiB**
- median CPU: **0.084%**
- all runs had 8 processes and passed readiness

## Interpretation

The fully initialized authenticated diagnostic state is consistently about 133–146 MiB above the 250 MiB private-resident design target. CPU is within the 0.2% median design target in all three repetitions, so memory remains the primary problem.

The renderer remains the dominant private-resident owner. The measured variance across these fresh five-minute runs is about 12.30 MiB peak-to-peak at the complete-tree median, so future changes smaller than that need more repetitions before being treated as real improvements.

The CDP heap values and native sampling remain attribution evidence only. The captures do not justify calling the complete renderer footprint JavaScript memory or selecting a renderer behavior change. No functionality, media quality, hardware acceleration, cache policy, or working-set state was altered.

## Next step

Use this range as the readiness-gated diagnostic baseline while running a controlled static-text versus media-heavy transition in the same renderer lifetime. Preserve per-PID private working set, private bytes, V8 heap, DOM/media counts, GPU memory, and allocation-family maps before and after the transition. Only a repeatable workload-dependent delta should become the first optimization hypothesis.
