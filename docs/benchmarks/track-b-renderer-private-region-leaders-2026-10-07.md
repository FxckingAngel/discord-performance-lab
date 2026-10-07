# Track B renderer private-region leaders

Date: 2026-10-07

The read-only resident classifier now preserves the 32 largest committed
private-writable regions for the selected PID, including base address, commit
size, protection flags, and resident bytes. It does not read page contents.

Artifact:
`artifacts/track-b-live-memory-regions-20261007/renderer-resident-types.json`

Module correlation:
`artifacts/track-b-live-memory-regions-20261007/renderer-region-module-correlation.json`

## Current renderer sample

Renderer PID: 28160

- Private-writable committed: 345.04 MiB
- Private-writable resident: 295.78 MiB
- Largest region: 22.75 MiB committed, 20.52 MiB resident
- Ten largest regions: 117.53 MiB committed, 94.08 MiB resident
- Two regions were 16 MiB or larger.
- None of the 32 recorded regions overlapped a loaded module range.
- The largest ten regions are mostly `PAGE_READWRITE`; one of the large
  regions is executable-writable and must not be interpreted as ordinary heap
  without symbol or allocation-site evidence.

## Interpretation

The large-region list narrows the native-memory investigation. A relatively
small number of multi-megabyte private regions account for a substantial part
of the renderer's resident footprint, while many smaller regions account for
the rest. The list alone cannot identify whether a region belongs to V8,
Blink, a graphics allocator, WebRTC, or Discord application state.

The addresses are local diagnostic identifiers and are not published with
page contents or command lines. Reserved address space remains excluded from
the RAM KPI.

## Follow-up sample

A second read-only sample of the same live renderer recorded 288.16 MiB
private-writable resident and 336.84 MiB committed private-writable. Its ten
largest regions accounted for 115.78 MiB committed and 92.86 MiB resident,
with a largest resident region of 20.56 MiB. None of the 32 regions matched a
loaded module in this sample either. The region composition is therefore
stable enough to justify deeper allocator attribution, but not yet a reason to
change the renderer configuration.

## Allocation-base grouping

The follow-up classifier also preserved Windows allocation bases. Among the
32 largest regions, three allocation groups dominated the sample:

- 16 regions: 70.25 MiB committed, 68.79 MiB resident
- 5 regions: 60.50 MiB committed, 54.41 MiB resident
- 4 regions: 17.75 MiB committed, 17.75 MiB resident

These groups are still anonymous native allocations. Allocation-base
grouping narrows the next investigation, but it does not identify ownership
as V8, Blink, graphics, WebRTC, or Discord state.
