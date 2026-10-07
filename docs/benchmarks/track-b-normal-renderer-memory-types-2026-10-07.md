# Track B live renderer memory classification

Date: 2026-10-07  
Renderer PID: 43892  
Source: `artifacts/track-b-normal-renderer-memory-types-20261007.json`

This is a read-only classification of the renderer from the current normal Track B process. It is diagnostic evidence only because the normal shell was not connected to CDP for an application-readiness check.

## Resident and committed memory

| Category | Amount |
| --- | ---: |
| Private-writable resident | 255.50 MiB |
| Private-executable resident | 0.02 MiB |
| Other private resident | 0.81 MiB |
| Total classified private resident | 256.33 MiB |
| Committed private-writable | 349.17 MiB |
| Committed mapped | 394.09 MiB |
| Committed image | 369.62 MiB |
| Mapped resident | 19.68 MiB |
| Image resident | 51.86 MiB |

Reserved virtual address space is excluded from the resident figures.

## Largest allocation-base families

| Allocation family | Regions | Resident | Committed |
| --- | ---: | ---: | ---: |
| `0x3C000000000` | 16 | 67.56 MiB | 68.50 MiB |
| `0x410C00000000` | 2 | 58.66 MiB | 67.75 MiB |
| `0x7FFEC31C0000` | 1 | 10.23 MiB | 11.50 MiB |
| `0x233500000000` | 2 | 9.22 MiB | 10.00 MiB |

The two largest families account for approximately 126.2 MiB resident. Their allocation-base addresses are local diagnostic identifiers, not ownership labels. The measurement does not yet prove whether either family belongs to Blink, PartitionAlloc, Skia, compositor surfaces, WebView2 runtime state, or Discord-created state.

## Next attribution step

Track these two families across a blank shell, Discord initialization, the canonical authenticated route, media navigation, and return to the canonical route. Correlate their deltas with CDP aggregate resource counts and synchronized process measurements before changing renderer behavior.

