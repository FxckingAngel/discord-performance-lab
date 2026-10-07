# Track B current renderer allocation groups

Date: 2026-10-07  
Renderer PID: `26104`  
Shell root: `41888`  
Mode: read-only diagnostic

The current renderer was inspected with `VirtualQueryEx` and `QueryWorkingSetEx`. No renderer behavior, working set, or page state was changed. The classification is per-process and does not deduplicate physical pages shared with other WebView2 processes.

## Renderer ledger

| Metric | Result |
| --- | ---: |
| Resident pages | 272.664 MiB |
| Private-writable resident | 228.117 MiB |
| Private executable resident | 0.012 MiB |
| Private other resident | 0.348 MiB |
| Mapped resident | 5.750 MiB |
| Image resident | 38.438 MiB |
| Committed private-writable | 330.672 MiB |
| Committed mapped | 397.086 MiB |
| Committed image | 369.633 MiB |
| Private-writable regions | 2,067 |

The classifier's 272.664 MiB resident total was captured separately from the process-tree sample, whose renderer private working set was approximately 217 MiB. The difference is therefore treated as a cross-sample measurement boundary, not as an exact contradiction or a new memory metric.

## Largest private-writable allocation-base families

| Allocation base | Regions | Resident | Committed |
| --- | ---: | ---: | ---: |
| `0x29500000000` | 14 | 76.617 MiB | 78.250 MiB |
| `0x2B1C00000000` | 4 | 37.516 MiB | 42.250 MiB |
| `0x7FFCA8600000` | 1 | 10.719 MiB | 11.750 MiB |
| `0x6A3200000000` | 2 | 10.457 MiB | 11.250 MiB |
| `0x3F0800000000` | 4 | 7.027 MiB | 17.746 MiB |

The largest two families account for 114.133 MiB of resident private-writable pages in this capture. They are allocation ownership groups only. The current evidence does not identify them as Blink, Skia, compositor, media, or Discord application state.

## Follow-up shared-page accounting

A later read-only classifier capture of the same renderer reported:

| Metric | Result |
| --- | ---: |
| Private resident, all private protections | 225.414 MiB |
| Private resident marked shared in this process | 3.680 MiB |
| Estimated private resident excluding shared-flag pages | 221.734 MiB |

The estimated private-resident figure excludes pages whose `QueryWorkingSetEx` Shared bit is set within this renderer. It is not a cross-process unique-physical-page measurement and does not replace the complete-tree private-working-set KPI.

## Next experiment

Track these exact allocation bases through blank WebView2, Discord load, canonical static route, media-heavy route, and return to the canonical route. A group becomes an optimization candidate only if it appears or expands with a verified Discord workload and contracts when that workload becomes inactive. Fixed groups remain runtime-floor evidence.
