# Track B live allocation-family watch

Date: 2026-10-07

This is a read-only six-capture watch of the restored Track B renderer on the primary 1920x1080, 60 Hz display. It records Windows private-writable allocation-base families and the complete process tree. It does not navigate Discord, change renderer settings, force garbage collection, trim working sets, clear caches, or touch official Discord.

Raw output remains local under `artifacts/track-b-live-allocation-watch-20261007-115121/`.

## Scope and limitation

The shell was sampled from its existing state, but a manual route/readiness checkpoint was not established for this capture. It is therefore diagnostic evidence only and is not an authenticated acceptance baseline.

The renderer PID remained 51892 for all six allocation-family captures. The complete tree contained eight processes in all seven process-tree samples. The window remained visible, unminimized, and responsive.

## Process-tree summary

| Role | Private working set median | Working set median | Private bytes median |
| --- | ---: | ---: | ---: |
| Renderer | 327.58 MiB | 423.50 MiB | 369.04 MiB |
| GPU process | 38.30 MiB | 95.12 MiB | 137.89 MiB |
| WebView2 browser | 46.20 MiB | 147.59 MiB | 55.91 MiB |
| Native shell | 10.46 MiB | 62.74 MiB | 13.71 MiB |
| Network service | 11.62 MiB | 47.98 MiB | 16.98 MiB |
| Audio service | 3.37 MiB | 24.49 MiB | 8.14 MiB |
| Storage service | 3.23 MiB | 20.25 MiB | 7.84 MiB |
| Crashpad | 2.05 MiB | 18.41 MiB | 3.34 MiB |
| **Complete tree** | **442.87 MiB** | **840.30 MiB** | **611.87 MiB** |

The complete-tree CPU median was 0.000% in this short sample and the p95 was 0.748%. That is diagnostic only; it does not replace the longer settled CPU benchmark.

## Allocation-family result

The largest family varied from 40.938 to 52.312 MiB resident and from 41.25 to 53.00 MiB committed. The second family varied only 1.766 MiB resident. The third family was unchanged.

| Family | Observations | Resident range | Resident change, first to last | Committed range | Ownership status |
| --- | ---: | ---: | ---: | ---: | --- |
| `0x3E200000000` | 6 | 40.938–52.312 MiB | +9.688 MiB | 41.25–53.00 MiB | Unresolved |
| `0x6F1400000000` | 6 | 26.637–28.402 MiB | +1.766 MiB | 27.625–29.625 MiB | Unresolved |
| `0x19B000000000` | 6 | 17.719–17.719 MiB | 0 MiB | 17.719–17.719 MiB | Unresolved |
| `0x36FB00000000` | 6 | 10.223–11.184 MiB | +0.961 MiB | 10.50–12.25 MiB | Unresolved |

The first two captures of the process-tree sample showed a higher renderer private working set before it settled into the approximately 325–349 MiB range. Because no route or readiness marker was captured, that change cannot yet be attributed to Discord navigation, media, or ordinary warm-up.

## Decision

No production optimization was selected from this watch. The largest family is a useful lifecycle target because it moved by approximately 9.7 MiB during the observation, but the capture does not identify its allocator or prove that it is reclaimable. A valid next comparison still requires one manually confirmed fully initialized route and a controlled static-to-media-to-static transition using the same renderer.
