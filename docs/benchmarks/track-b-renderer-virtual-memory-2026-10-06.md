# Track B renderer virtual-memory attribution

Date: 2026-10-06

This was a read-only `VirtualQueryEx` classification of the normal Track B process tree after the renderer heap diagnostic. It classifies committed regions by Windows memory type and protection. It does not measure residency of each region and does not identify allocation owners or safe release points.

## Per-process result

| Role | Working set | Private bytes | Private committed | Private writable committed | Private executable committed |
| --- | ---: | ---: | ---: | ---: | ---: |
| Renderer | 412.3 MiB | 346.6 MiB | 334.4 MiB | 332.1 MiB | 10.9 MiB |
| GPU process | 106.8 MiB | 163.4 MiB | 128.0 MiB | 127.6 MiB | 0.0 MiB |
| WebView2 browser | 145.1 MiB | 48.6 MiB | 37.1 MiB | 36.6 MiB | 0.0 MiB |
| Network service | 51.0 MiB | 15.4 MiB | 9.1 MiB | 8.9 MiB | 0.0 MiB |
| Native shell | 53.9 MiB | 11.2 MiB | 7.1 MiB | 7.0 MiB | 0.0 MiB |

The renderer is dominated by committed private regions in this point-in-time classification. The writable and executable columns are protection classifications, not disjoint buckets. A page with execute-write protection can be counted in both, so they must not be added together.

This does not prove that the private committed renderer memory is Discord application state, Blink state, decoded media, allocator slack, or removable cache. It also does not replace private working set as the primary resident-memory KPI.

## Decision impact

The result strengthens the renderer-first allocation gate. It does not authorize working-set trimming, forced paging, forced garbage collection, disabling hardware acceleration, or deleting Discord state. The next useful comparison is a controlled static-versus-media workload using the same per-PID and CDP aggregate capture path.

Raw input: `artifacts/track-b-current-virtual-memory-types.json`.
