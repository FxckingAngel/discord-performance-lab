# Track B current post-restart follow-up

Date: 2026-10-07

This was a read-only 30-second observation of the existing normal shell after its latest restart. The route, account state, and workload were not independently verified, so it is not an acceptance benchmark.

## Results

- Samples: 5 at 5-second intervals
- Process tree: 8 processes throughout
- Private working set: 386.98 MiB median, 388.76 MiB p95
- Private bytes: 576.09 MiB median, 617.30 MiB p95

Final per-process private working set:

- Renderer: 284.35 MiB
- GPU: 40.63 MiB
- Browser: 36.23 MiB
- Network service: 9.31 MiB
- Native shell: 6.20 MiB
- Audio service: 3.18 MiB
- Storage service: 3.10 MiB
- Crashpad: 1.50 MiB

## Interpretation

The current post-restart state is far above the earlier user-confirmed checkpoint of approximately 151 MiB private working set and 241.6 MiB private bytes. Because the route and workload are unverified, this does not prove a regression or a leak. It does establish that the lower state cannot be treated as a stable implementation result without repeated same-route checkpoints.
