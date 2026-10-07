# Track B blank versus loaded renderer trace

Date: 2026-10-07

These are two aggregate-only 30-second CDP traces using the same 60-second settle period. The trace tool discarded raw events, page text, URLs, cookies, tokens, and event arguments. The loaded run used `--diagnostic-authenticated-no-bridges`; the blank run used `--diagnostic-blank`. Neither route or account workload was independently verified.

The trace tool now also writes `summary.eventRatesPerSecond` for the selected activity classes, so future captures with different durations can be compared without manually normalizing counts.

## Activity comparison

| Aggregate event | Blank | Loaded |
| --- | ---: | ---: |
| RunTask | 599 | 5,177 |
| FunctionCall | 0 | 707 |
| UpdateLayoutTree | 0 | 33 |
| Layout | 0 | 40 |
| Paint | 0 | 375 |
| AnimationFrame | 0 | 388 |
| TimerFire | 0 | 263 |
| Timer install | 0 | 201 |
| Blink microtask checkpoints | 18 | 1,959 |
| Memory-dump events | 8 process dumps | 15 periodic intervals |

The loaded state also recorded 416 `LocalFrameView::UpdateStyleAndLayout` events, 222 forced style/layout events, 194 animation service events, 194 animation-frame render events, and 375 paint events. The blank shell recorded no layout, paint, animation-frame, timer-fire, or function-call activity in the selected trace summary.

## Interpretation

The loaded diagnostic state is not behaving like a truly static document. It has a sustained animation, timer, microtask, layout, and paint workload even after the settle period. This is a concrete CPU/wakeup and compositor investigation target, but it does not identify which Discord feature owns the activity because the route and viewport workload were not independently verified.

The trace does not justify disabling animation, media, or hardware acceleration globally. The next controlled comparison should use a manually confirmed static Discord channel, then repeat with visible animated media, preserving the same window and account state.

Raw traces are in `artifacts/track-b-current-cdp-trace-20261007.json` and `artifacts/track-b-blank-cdp-trace-20261007.json`.
