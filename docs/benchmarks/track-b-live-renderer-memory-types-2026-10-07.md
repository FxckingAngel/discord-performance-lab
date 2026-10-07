# Track B live renderer memory types: 2026-10-07

Status: read-only diagnostic evidence. The capture targeted the renderer descendant of the currently running normal Track B shell. The exact Discord route and visible workload were not manually confirmed, so this is not an acceptance benchmark.

The official Discord installation was not touched.

## Renderer ledger

| Classification | Resident | Committed |
| --- | ---: | ---: |
| Total renderer resident | 408.44 MiB | 1,091.37 MiB |
| Private-writable | 294.87 MiB | 325.38 MiB |
| Private-executable | 0.02 MiB | 0.02 MiB |
| Other private | 1.06 MiB | 2.31 MiB |
| Mapped | 43.81 MiB | 394.03 MiB |
| Image | 68.68 MiB | 369.62 MiB |

The reported reserved address space was approximately 3.53 TiB. It is virtual address reservation and is not counted as RAM.

## Private-writable region distribution

- 2,148 private-writable regions were observed.
- Regions under 64 KiB accounted for 42.34 MiB resident.
- Regions from 64 KiB to 1 MiB accounted for 71.29 MiB.
- Regions from 1 MiB to 4 MiB accounted for 78.81 MiB.
- Regions from 4 MiB to 16 MiB accounted for 58.68 MiB.
- Regions 16 MiB or larger accounted for 43.76 MiB across three regions.

## Interpretation

This confirms that the current renderer's private-resident gap is predominantly private-writable native memory, not executable code pages. It does not identify the allocator or owner of those pages. The region-size distribution alone cannot distinguish Discord application state, Blink structures, image/media backing, compositor resources, or WebView2 runtime arenas.

No renderer behavior was changed. The next attribution step must correlate these region families with lifecycle and workload transitions, or with a decoded allocation-stack source, before any cache or renderer optimization is selected.
