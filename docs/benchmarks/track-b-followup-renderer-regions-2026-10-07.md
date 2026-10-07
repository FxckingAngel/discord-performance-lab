# Track B current renderer resident-region follow-up

Date: 2026-10-07  
Renderer PID: 28160  
State: current settled shell state after the settled process-tree baseline

## Read-only classification

The VirtualQueryEx and QueryWorkingSetEx scan reported:

| Measure | Value |
| --- | ---: |
| Total renderer resident memory classified | 325.547 MiB |
| Private-writable resident | 275.996 MiB |
| Private executable resident | 0.008 MiB |
| Private other resident | 0.367 MiB |
| Committed private-writable memory | 422.672 MiB |
| Mapped resident | 6.133 MiB |
| Image resident | 43.043 MiB |
| Private-writable regions | 2,504 |
| Largest regions inspected | 32 |
| Largest regions matching loaded modules | 0 |

Reserved virtual address space is excluded from the resident-memory totals.
Private bytes and committed memory remain separate from resident memory.

## Allocation-base groups

The largest allocation-base groups in the scanned region set were:

| Allocation base | Regions | Resident | Committed |
| --- | ---: | ---: | ---: |
| `0x39400000000` | 18 | 87.484 MiB | 89.500 MiB |
| `0x5E0C00000000` | 5 | 51.124 MiB | 62.000 MiB |
| `0x7FFEC31C0000` | 1 | 15.660 MiB | 16.750 MiB |
| `0xF6700000000` | 1 | 5.180 MiB | 5.250 MiB |
| `0x4AE800000000` | 1 | 1.164 MiB | 11.652 MiB |

The first two anonymous groups account for 138.608 MiB of resident memory.
They are close to the previously observed large anonymous groups, but their
allocation-base identity alone cannot distinguish Chromium allocator arenas,
Blink state, media surfaces, or another native owner.

## Decision boundary

This is read-only evidence only. It does not justify trimming, forced paging,
garbage collection, a Chromium flag, or a renderer change. The next owner
test remains a paired static-text versus media-heavy WPR heap capture with
decoded allocation stacks and the same region grouping beside it.

The raw classification and module-correlation outputs remain private under
`artifacts/track-b-followup-settled-current/`.
