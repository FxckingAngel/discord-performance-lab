# Track B foreground versus minimized isolation: 2026-10-06

Status: read-only isolation evidence. The route and workload were not independently verified, and each state was observed for only 30 seconds.

Sources:

- `artifacts/track-b-foreground-minimized-30s-20261006/foreground.json`
- `artifacts/track-b-foreground-minimized-30s-20261006/minimized.json`

The same running shell was measured in the foreground, then minimized, then restored in a `finally` path. No runtime flags or application settings changed.

## Process-tree comparison

| State | Private working set median | Private bytes median | CPU median | CPU p95 |
| --- | ---: | ---: | ---: | ---: |
| Foreground | 406.76 MiB | 564.65 MiB | 0.065% | 0.114% |
| Minimized | 406.75 MiB | 563.49 MiB | 0.082% | 0.116% |

The medians hide a delayed transition during the minimized window. The first four minimized samples remained near the foreground level, then the renderer dropped from about 309 MiB to 273–275 MiB private working set and the complete tree dropped from about 407 MiB to about 372 MiB.

## Role observations

- Foreground renderer: 307–308 MiB near the end of the control window
- Minimized renderer after the delayed drop: 273–275 MiB
- GPU process: approximately 37.4 MiB in both states
- The complete-tree reduction after the delayed renderer drop was approximately 34 MiB

## Interpretation

Minimization releases a meaningful renderer-resident allocation after a delay, while the GPU process remains stable. This is consistent with viewport, visibility, compositor, or page-lifecycle resources rather than a GPU-process allocation. The normal shell already sets the WebView invisible while minimized, so this result does not identify an additional safe foreground optimization.

The minimized state still does not approach the approximately 250 MiB foreground target. Do not treat minimizing, paging, or working-set trimming as the optimization. The next candidate must explain and safely release an equivalent category while the Discord window remains usable in the foreground.
