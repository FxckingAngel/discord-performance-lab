# Track B current renderer allocation-family comparison

Date: 2026-10-07

This is a read-only comparison between the current ordinary Track B shell and the same-build blank renderer boundary. It does not change renderer behavior and does not claim an allocation owner. Official Discord was not touched.

Raw process and virtual-memory captures remain private under `artifacts/track-b-current-normal-allocation-20261007/`.

## Current shell state

The ordinary shell root was PID 40832. The final process-tree sample contained eight processes. The renderer was PID 46360.

| Metric | Complete tree | Renderer |
| --- | ---: | ---: |
| Total working set | 827.4 MiB | 416.1 MiB |
| Private working set | 424.37 MiB | 312.63 MiB |
| Private bytes | 591.3 MiB | 353.0 MiB |
| Read-only classified resident | — | 405.14 MiB |
| Private-writable resident | — | 301.27 MiB |
| Committed private-writable | — | 338.08 MiB |

The process-tree private-working-set value and the virtual-memory classifier use different sampling paths, so the classified renderer resident value is not substituted for the process-tree KPI.

## Allocation-family result

The blank boundary renderer measured 43.34 MiB total resident and 7.20 MiB private-writable resident. The current renderer measured 405.14 MiB total resident and 301.27 MiB private-writable resident.

Rank-based group comparison found the following current private-writable families:

| Rank | Blank resident | Current resident | Delta | Current committed | Regions | Protection |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 3.07 MiB | 87.26 MiB | +84.19 MiB | 88.00 MiB | 14 | PAGE_READWRITE |
| 2 | 0.56 MiB | 29.00 MiB | +28.43 MiB | 29.75 MiB | 7 | PAGE_READWRITE |
| 3 | 0.52 MiB | 15.81 MiB | +15.29 MiB | 15.81 MiB | 3 | PAGE_READWRITE |
| 4 | 0.15 MiB | 11.88 MiB | +11.73 MiB | 12.25 MiB | 2 | PAGE_READWRITE |
| 5 | 0.07 MiB | 9.25 MiB | +9.18 MiB | 9.75 MiB | 1 | PAGE_READWRITE |

The first three families alone account for about 132.1 MiB of current resident private-writable memory and about 127.9 MiB above the blank comparison ranks. The first five account for about 153.2 MiB current resident and about 148.8 MiB above the corresponding blank ranks.

## Module correlation and limits

The read-only module correlation matched zero of the 32 largest private-writable regions to a loaded module. The large families therefore do not appear to be simple image-backed module pages. This still does not identify them as Blink, Skia, PartitionAlloc, WebView2 infrastructure, or Discord application state. Allocation-base addresses are process-specific and are not used as cross-process identity.

The evidence supports one narrow conclusion: Discord-loaded state creates several large private-writable resident families that are absent or almost absent at the blank boundary. It does not support a renderer optimization yet. The next valid step is stack or lifecycle attribution for these families, followed by one reversible experiment tied to an identified owner.

No working-set trimming, forced paging, forced garbage collection, feature disabling, or Chromium flag change was used.
