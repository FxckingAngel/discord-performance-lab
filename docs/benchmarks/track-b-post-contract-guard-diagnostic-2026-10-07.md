# Track B post-contract-guard diagnostic

Date: 2026-10-07

Artifact: `artifacts/track-b-post-contract-guard-diagnostic-20261007/process-tree.json`

This is a short, route-unverified observation of the normal Track B shell after the atomic boot-contract guard was rebuilt. It did not expose `DiscordNative`, did not change Discord behavior, and did not touch the official client. Because the route and workload were not manually confirmed, it is not an acceptance benchmark.

| Metric | Result |
| --- | ---: |
| Samples | 4 |
| Process count | 8 |
| Complete-tree private working set, median | 396.44 MiB |
| Complete-tree private working set, range | 389.98–397.50 MiB |
| Renderer private working set, median | 290.87 MiB |
| Renderer private working set, range | 286.08–293.08 MiB |
| CPU, median | 0.065% |
| CPU, maximum | 0.634% |

The sample is consistent with the existing fully loaded diagnostic range. It does not show a memory or CPU change from the contract guard. The normal shell remains the known-good no-`DiscordNative` path.
