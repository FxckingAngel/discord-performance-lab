# Track B authenticated lifecycle after bridge fix

Date: 2026-10-07  
Capture: `artifacts/track-b-lifecycle-fixed-20261007`  
Mode: automatic timed checkpoints on the fixed diagnostic build

This is the first lifecycle capture in this series where the authenticated Discord application passed the readiness predicate. The endpoint-ready checkpoint is intentionally excluded because it precedes application initialization. All later checkpoints had a populated Discord mount and a fully loaded `/channels/@me` route class.

## Results

| Checkpoint | Application ready | DOM nodes | Tree private WS | Renderer private WS | V8 used | Median CPU |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Startup, 5 s | yes | 4,491 | 564.71 MiB | 444.25 MiB | 103.66 MiB | 0.493% |
| Startup, 15 s | yes | 4,502 | 471.13 MiB | 354.86 MiB | 102.60 MiB | 0.424% |
| Startup, 30 s | yes | 4,502 | 425.70 MiB | 311.73 MiB | 102.19 MiB | 0.429% |
| Startup, 60 s | yes | 4,498 | 408.31 MiB | 296.88 MiB | 104.55 MiB | 0.540% |
| Settled, 3 min | yes | 4,554 | 411.24 MiB | 296.57 MiB | 110.17 MiB | 0.355% |
| Settled, 5 min | yes | 4,612 | 416.71 MiB | 299.11 MiB | 98.33 MiB | 0.023% |

The tree contained the native shell and WebView2 browser, crashpad, GPU, network, storage, audio, and renderer processes. The capture preserved per-role data in the private raw artifacts.

## Interpretation

This establishes a valid full-state baseline, not an optimization result. The five-minute settled state is approximately 166.7 MiB above the 250 MiB private-resident target, with the renderer accounting for most of the gap. V8 used heap is approximately 98.3 MiB at that checkpoint, leaving a substantial native renderer remainder for the allocation-family work.

CPU is within the 0.2% median target at the five-minute sample but is not yet a repeated acceptance result. The high startup CPU values are initialization cost and are reported separately from settled idle.

The authenticated diagnostic was run without the incomplete window/hardware bridge. Official Discord was not modified. The normal Track B shell was restored after capture and remained responsive.

