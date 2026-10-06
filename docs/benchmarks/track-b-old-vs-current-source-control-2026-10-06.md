# Track B old-versus-current source control

Date: 2026-10-06

This control compares the current verified build with an older source checkout from before the diagnostic capability-call instrumentation. Both runs used the same persisted Track B profile and the same 10-minute settled benchmark shape. The comparison is informative, not a proof of a code-only regression, because the process and profile state can still vary between sequential runs.

## Results

| Build | Duration | Samples | Working set median / p95 | Private working set median / p95 | Private bytes median / p95 | CPU median / p95 | Processes | Renderers |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Older source, `b6b1904` | 621.5 s | 20 | not retained in this control note | not retained in this control note | 258.42 / 268.12 MiB | 0.016 / 0.016% | 7 | 1 |
| Current source, final control | 621.0 s | 20 | 511.42 / 519.23 MiB | 167.86 / 178.03 MiB | 246.25 / 258.37 MiB | 0.027 / 0.027% | 7 | 1 |

The current run also measured 345.10 MiB median shareable working set, 246.25 MiB median commit, 3,612 median handles, and 182.5 median threads. Its renderer accounted for 107.30 MiB median private bytes and 119.70 MiB at p95. The browser process accounted for 42.29 MiB median private bytes and the GPU process 58.33 MiB.

## Interpretation

The current build did not show a memory increase relative to the older source control. Its private-bytes median was 12.17 MiB lower and its p95 was 9.75 MiB lower. The current run's CPU was 0.011 percentage points higher, but both measurements are near the idle floor and this sequential comparison is not sufficient to attribute that difference to the capability-call logging.

The normal build does not enable capability-call logging. The instrumentation is diagnostic-only and is gated behind the authenticated capability-events command-line mode. No conclusion is made about authenticated route-specific behavior from these idle runs.

The strict Track B target remains approximately 250 MiB total settled idle private/commit memory and 0.2% total idle CPU across the process tree. This control is close on median private bytes but still above the target at p95, so it is not an acceptance pass. The attached screenshot's blank content area is also not treated as a functional pass; native-window verification remains separate from this resource control.

## Inputs

- `benchmarks/raw/track-b-old-source-settled-10min-20261006-summary.json`
- `benchmarks/raw/track-b-current-after-old-source-control-10min-summary-20261006.json`

