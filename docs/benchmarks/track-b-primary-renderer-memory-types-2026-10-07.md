# Track B primary renderer memory classification

Date: 2026-10-07

This is a read-only VirtualQueryEx and QueryWorkingSetEx classification for the renderer from the corrected primary-monitor baseline. It does not identify allocator ownership by itself and does not change renderer behavior.

Raw output remains under `artifacts/track-b-primary-1280x720-20261007/renderer-memory-types.json`.

## Renderer totals

- Process: WebView2 renderer PID 43244
- Working set: 405.91 MiB
- Private resident: 312.78 MiB
- Unique private resident within this process: 312.77 MiB
- Private writable resident: 311.69 MiB
- Private executable resident: 0.02 MiB
- Private other resident: 1.06 MiB
- Mapped resident: 23.46 MiB
- Image resident: 69.68 MiB
- Committed private writable: 350.95 MiB
- Reserved virtual address space: 3.52 TiB; excluded from RAM accounting

## Largest private-writable allocation-base families

| Family | Regions | Resident | Committed |
| --- | ---: | ---: | ---: |
| `0x9E00000000` | 15 | 70.06 MiB | 70.75 MiB |
| `0x5AD800000000` | 5 | 56.61 MiB | 58.13 MiB |
| `0x663000000000` | 4 | 29.18 MiB | 29.18 MiB |
| `0x5AA800000000` | 1 | 11.72 MiB | 12.00 MiB |

The first three families account for approximately 155.85 MiB resident. They are process-local addresses and are not yet named as Blink, Skia, compositor, PartitionAlloc, or Discord state. Ownership still requires lifecycle correlation or stack evidence.

## Interpretation

The remaining renderer memory is predominantly private writable resident memory rather than executable code or mapped/image pages. This strengthens the native/private allocation investigation and rejects treating the whole renderer as JavaScript memory. The next valid step is to track these families across a stable static-to-media-to-static transition and compare their resident and committed deltas with DOM, decoded media, compositor, GPU, and V8 measurements.
