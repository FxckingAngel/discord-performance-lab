# Track B current settled follow-up baseline

Date: 2026-10-07  
Scenario: current authenticated shell state, minimized, same window and
display  
Root PID: 39116  
Measurement: 13 samples over 60 seconds after the strict settle gate passed
after 18 probes

## Complete process tree

| Metric | Median | P95 |
| --- | ---: | ---: |
| Process count | 8 | 8 |
| Total working set | 551.36 MiB | 554.72 MiB |
| Private working set | 331.91 MiB | 335.18 MiB |
| Shareable working set | 219.52 MiB | 219.55 MiB |
| Private bytes | 694.85 MiB | 697.63 MiB |
| CPU | 0.016% | 0.364% |

The primary resident-memory KPI is private working set. Private bytes remain a
separate committed-memory measure and are not substituted for resident RAM.
The ordinary working-set sum is retained for comparison, but shareable pages
must not be added to private working set as unique physical memory.

## Per-role resident breakdown

| Role | Private working set | Working set | Private bytes |
| --- | ---: | ---: | ---: |
| Renderer, PID 28160 | 277.59 MiB | 335.04 MiB | 436.73 MiB |
| Browser, PID 39032 | 21.29 MiB | 68.53 MiB | 51.82 MiB |
| GPU, PID 6372 | 21.24 MiB | 46.41 MiB | 158.73 MiB |
| Network service, PID 39524 | 7.80 MiB | 34.86 MiB | 18.41 MiB |
| Native shell, PID 39116 | 1.47 MiB | 22.18 MiB | 10.55 MiB |
| Audio service, PID 32012 | 0.91 MiB | 15.52 MiB | 7.87 MiB |
| Crashpad, PID 40452 | 0.39 MiB | 15.11 MiB | 2.85 MiB |
| Storage service, PID 39096 | 1.39 MiB | 13.96 MiB | 7.89 MiB |

The renderer is 83.64% of the complete-tree private working set. Holding the
other processes constant, reaching the 250 MiB complete-tree target would
require approximately 145.7 MiB of renderer private working set, so the
renderer remains the only large enough target to justify deeper attribution.

## Stability and interpretation

- The strict settle gate required 18 probes because the earlier state was not
  stable within the 1% renderer/GPU variation limit.
- Once the gate passed, the 13-sample measurement stayed within a narrow band.
- The shell window handle, process roles, eight-process tree, minimized state,
  and 1920x1080 at 60 Hz remained unchanged.
- CPU is already below the 0.2% median target. Further idle CPU work is
  deferred unless a longer repeated baseline regresses.
- No renderer behavior, Chromium flags, working-set trimming, or garbage
  collection was changed for this measurement.

The raw measurement remains private at
`artifacts/track-b-followup-settled-current/measurement.json`, with the
sanitized summary at
`artifacts/track-b-followup-settled-current/measurement-summary.json`.

The next attribution gate is still an elevated paired WPR capture of a settled
static text state and a settled media-heavy state. The current WPR snapshot
decoder does not yet account for the renderer's native resident remainder, so
this baseline does not justify a renderer change by itself.
