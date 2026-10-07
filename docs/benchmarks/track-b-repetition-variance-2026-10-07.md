# Track B repetition variance analysis

Source: `artifacts/track-b-post-heap-snapshot-repeated-20261007/`  
Capture window: 2026-10-07 01:51:41–01:55:27 local diagnostic time

## Identity controls

The three repetitions were not different process launches. All used the same:

- root PID 39116
- renderer PID 28160
- GPU PID 6372
- browser PID 39032
- eight-process tree
- window handle 12061962
- visible, responsive, minimized shell
- 1920x1080 display at 60 Hz
- renderer lifetime increasing continuously across all repetitions

Therefore the variance is not caused by summing different renderer PIDs or by a changed display configuration.

## Observed transition

Repeat 1 settled around 230–238 MiB renderer private working set and 28 MiB GPU private working set.

Repeat 2 began in the same band, then changed during the capture:

| Time | Renderer private WS | GPU private WS | Renderer WS | GPU WS |
| --- | ---: | ---: | ---: | ---: |
| 01:53:27 | 236.86 MiB | 27.95 MiB | 297.57 MiB | 76.59 MiB |
| 01:53:33 | 252.24 MiB | 45.11 MiB | 320.16 MiB | 99.96 MiB |
| 01:53:45 | 338.68 MiB | 56.05 MiB | 409.05 MiB | 111.23 MiB |
| 01:53:57 | 378.13 MiB | 93.60 MiB | 464.97 MiB | 158.49 MiB |
| 01:54:09 | 434.25 MiB | 102.19 MiB | 513.97 MiB | 166.24 MiB |

Repeat 3 started in the elevated state and decayed gradually. By the end, renderer private WS was 344.27 MiB and GPU private WS was 84.97 MiB. This indicates a genuine renderer/GPU allocation phase or delayed release, not a sampling-counter error confined to one process.

## Baseline consequence

The three-run set does not establish a single normal idle band. The low state and elevated state must be treated as separate states until the workload that triggers the transition is identified. Small improvements must not be judged against the low state while the same test can enter the elevated state.

The next baseline runner must require a settle condition before recording the acceptance window:

1. Keep the route, media visibility, call state, window state, and display fixed.
2. Sample the complete tree every five seconds.
3. Require at least six consecutive samples where renderer private WS and GPU private WS each vary by no more than 1% peak-to-peak.
4. Record the scenario metadata and then collect the measurement window.
5. Reject the run if process count, renderer PID, window state, or workload metadata changes.

For a diagnostic CDP run, the settle record must also include V8 used heap, DOM/document counts, image/video/canvas counts, and navigation age. The ordinary stock shell does not expose CDP, so those fields remain unavailable for these three normal-shell repetitions.

## Current interpretation

The simultaneous renderer/GPU increase makes a compositor, decoded-media, canvas, or GPU-backed surface transition more plausible than a pure JavaScript heap explanation. It is not sufficient to select one of those owners. The next controlled comparison remains static text versus media-heavy content, with WPR heap decoding and private region groups recorded at the low and elevated states.

No renderer behavior was changed.
