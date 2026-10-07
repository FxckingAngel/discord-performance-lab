# Track B live renderer region attribution

Date: 2026-10-06

Artifact directory: `artifacts/track-b-live-attribution-refresh-20261006/`

The currently running Release shell was observed for about 30 seconds without restarting it. The capture contained eight processes. At the final process-tree sample:

| Measure | Result |
| --- | ---: |
| Summed working set | 845.2 MiB |
| Complete-tree private working set | 427.4 MiB |
| Complete-tree private bytes | 587.7 MiB |
| Renderer process private working set | 334.97 MiB |
| Renderer private-writable resident classification | 317.7 MiB |

## Renderer private-writable region shape

| Region size | Region count | Resident bytes |
| --- | ---: | ---: |
| Under 64 KiB | 1,664 | 43.6 MiB |
| 64 KiB–1 MiB | 445 | 59.4 MiB |
| 1–4 MiB | 42 | 68.4 MiB |
| 4–16 MiB | 9 | 84.3 MiB |
| 16 MiB or larger | 2 | 62.0 MiB |
| Total | 2,162 | 317.7 MiB |

The renderer's private-writable resident memory is therefore split between many small regions and a smaller number of larger arenas. Regions at least 4 MiB account for about 146.3 MiB, while the sub-1 MiB regions account for about 103.0 MiB. This does not identify allocator ownership, so it is not yet a justification for changing Discord or WebView2 behavior. It does identify the next diagnostic boundary: correlate the large-region deltas with blank/app-shell/static/media/voice/video scenarios, and use CDP or Chromium diagnostics only to attribute the corresponding feature state.

The route and workload were not manually verified during this capture. It is current runtime evidence, not an authenticated same-route acceptance benchmark.
