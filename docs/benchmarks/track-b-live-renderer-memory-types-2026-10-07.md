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

The largest allocation-base groups in the same capture were:

| Allocation base | Regions | Resident | Committed |
| --- | ---: | ---: | ---: |
| `0x2DE00000000` | 11 | 73.06 MiB | 74.00 MiB |
| `0x3AE400000000` | 7 | 24.93 MiB | 26.38 MiB |
| `0x2B9800000000` | 5 | 19.16 MiB | 19.57 MiB |
| `0x2CE200000000` | 2 | 9.56 MiB | 9.75 MiB |
| `0x7FFEC31C0000` | 1 | 9.09 MiB | 10.25 MiB |

These are process-local allocation-base addresses. They are not stable identities across renderer lifetimes because of address-space layout randomization. The first three groups account for approximately 117.16 MiB resident in this capture, but their owners remain unknown.

## Interpretation

This confirms that the current renderer's private-resident gap is predominantly private-writable native memory, not executable code pages. It does not identify the allocator or owner of those pages. The region-size distribution and allocation-base grouping alone cannot distinguish Discord application state, Blink structures, image/media backing, compositor resources, or WebView2 runtime arenas. The groups must be tracked across lifecycle and workload transitions or joined to allocation-stack evidence before they can be treated as optimization targets.

No renderer behavior was changed. The next attribution step must correlate these region families with lifecycle and workload transitions, or with a decoded allocation-stack source, before any cache or renderer optimization is selected.
