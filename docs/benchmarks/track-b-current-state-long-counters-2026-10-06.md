# Track B long fallback-counter capture

Date: 2026-10-06

This is a 63.7-second read-only Windows performance-counter capture against the current normal Track B shell. The route was not manually confirmed, so it is not an acceptance benchmark.

## Capture

- Samples: 13
- Requested interval: 5 seconds
- Process tree: 7 processes at every sample
- Raw data: `benchmarks/raw/track-b-current-state-route-unknown-long-counters-20261006.json`

Fallback counter observations:

- GPU engine utilization: 0% median and 0% p95
- Dedicated GPU memory: 17.49 MiB median
- Page faults: 0 median and 3.95/sec p95 across process rows
- Read I/O: 0 median bytes/sec
- Write I/O: 0 median bytes/sec

The process-counter rows sum to approximately 166.98 MiB private working set median and 256.80 MiB private bytes median. A separate `Measure-DiscordProcessTree.ps1` capture taken around the same restored shell state reported approximately 173.55 MiB private working set and 265.59 MiB private bytes. The difference is retained as a measurement-method discrepancy; it is not treated as a reduction or as proof that either metric passes the complete target.

The normal process-tree sampler remains the acceptance path because it records the complete rooted tree through direct process snapshots, while this fallback sampler exists for supplementary GPU, fault, and I/O counters. No process priority, working set, security setting, or Discord state was changed.
