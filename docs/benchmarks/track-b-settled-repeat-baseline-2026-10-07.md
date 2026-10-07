# Track B repeated settled baseline

Date: 2026-10-07  
Root PID: 39116  
Renderer PID: 28160  
Both runs used the same eight-process tree, window handle, minimized state,
and 1920x1080 at 60 Hz.

## Independent settled runs

| Run | Settle probes | Samples | Tree private WS median / p95 | Renderer private WS median / p95 | CPU median / p95 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Follow-up 01 | 18 | 13 | 331.91 / 335.18 MiB | 277.59 / 280.66 MiB | 0.016% / 0.364% |
| Follow-up 02 | 13 | 13 | 325.02 / 345.17 MiB | 269.67 / 290.95 MiB | 0.031% / 1.153% |

The two-run median of the run medians is 328.47 MiB complete-tree private
working set and 273.63 MiB renderer private working set. These are descriptive
repeat statistics, not a replacement for a larger baseline set.

## Interpretation

The strict settle gate passes within each final measurement window, but the
second run's p95 is higher and the run medians differ by 6.89 MiB for the
complete tree. The renderer remains the dominant owner in both runs. CPU is
already below the 0.2% median target, so idle CPU optimization remains
secondary.

The difference is not evidence of a safe optimization opportunity. It must be
explained or controlled before accepting small memory changes. The next
controlled owner test remains static text versus media-heavy WPR stack
decoding, paired with the per-PID and anonymous-region measurements.

Raw measurements remain private under:

- `artifacts/track-b-followup-settled-current/`
- `artifacts/track-b-followup-settled-repeat-02/`
