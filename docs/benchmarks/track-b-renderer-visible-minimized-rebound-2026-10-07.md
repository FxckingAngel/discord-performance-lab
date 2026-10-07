# Track B renderer minimization rebound

Date: 2026-10-07  
Renderer PID: 43892  
Capture: `artifacts/track-b-normal-renderer-memory-types-restored-20261007.json`

After the minimized-state capture, Track B was restored and left visible for 15 seconds before this read-only map. No renderer setting, flag, cache, or feature was changed.

| Measurement | Visible before minimize | Minimized | Restored visible |
| --- | ---: | ---: | ---: |
| Private-writable resident | 255.50 MiB | 222.07 MiB | 245.85 MiB |
| Regions ≥16 MiB resident | 81.48 MiB | 0.57 MiB | 45.96 MiB |
| `0x3C000000000` family | 67.56 MiB | 46.72 MiB | 81.02 MiB |
| `0x410C00000000` family | 58.66 MiB | 26.50 MiB | 27.52 MiB |

The partial rebound and redistribution show that minimization changes resident-page state and allocation grouping, but do not prove that either family is an idle cache that can be released safely while visible. This result is therefore attribution evidence only. It does not justify working-set trimming, forced paging, cache disabling, or a production renderer change.

The next valid A/B must keep the window visible and vary a real workload, such as static text versus media-heavy content, while preserving normal Discord behavior.

