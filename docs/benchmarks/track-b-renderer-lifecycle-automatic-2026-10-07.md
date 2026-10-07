# Track B renderer lifecycle capture

Date: 2026-10-07  
Mode: automatic canonical-route-unverified diagnostic  
Artifact: `artifacts/track-b-lifecycle-automatic-20261007/lifecycle-manifest.json`

This capture used only Track B's diagnostic shell and the existing authenticated WebView2 profile. It did not touch official Discord, clear caches, force garbage collection, trim working sets, or change renderer behavior. Because the exact route was not manually confirmed during the run, this is attribution evidence rather than an acceptance baseline.

## Same-renderer lifecycle

Renderer PID 30628 was retained from navigation through the ten-minute checkpoint. The page readiness predicate became true at the application-shell checkpoint and remained true. The process tree contained eight processes at the measured checkpoints.

| Checkpoint | Ready | Renderer private WS | Tree private WS | V8 used heap | DOM nodes | Images | GPU private WS |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Blank | no | 9.76 MiB | 92.19 MiB | 0.50 MiB | 8 | 0 | 16.85 MiB |
| Navigation | no | 535.04 MiB | 649.60 MiB | 54.68 MiB | 1,506 | 1 | 37.50 MiB |
| Application shell | yes | 500.43 MiB | 612.65 MiB | 168.06 MiB | 6,897 | 130 | 35.03 MiB |
| Canonical route | yes | 325.80 MiB | 434.37 MiB | 97.60 MiB | 5,872 | 130 | 35.64 MiB |
| Settled 1 minute | yes | 293.32 MiB | 401.27 MiB | 103.19 MiB | 5,880 | 129 | 38.06 MiB |
| Settled 5 minutes | yes | 286.72 MiB | 390.53 MiB | 108.00 MiB | 5,871 | 129 | 34.16 MiB |
| Settled 10 minutes | yes | 275.82 MiB | 379.45 MiB | 90.85 MiB | 5,934 | 133 | 34.72 MiB |

The tree private working-set values are sums of the per-process private working-set fields. They are not unique physical-page totals across processes.

## Allocation-family changes

The largest private-writable allocation families were tracked by allocation base within the same renderer lifetime:

| Allocation base | Navigation | Canonical route | Settled 10 minutes |
| --- | ---: | ---: | ---: |
| `0x33F00000000` | 237.49 MiB | 53.30 MiB | 64.88 MiB |
| `0xE2C00000000` | 56.33 MiB | 23.78 MiB | 39.21 MiB |
| `0x150000000000` | 40.42 MiB | 17.75 MiB | 17.75 MiB |

The largest family is therefore not a fixed blank-WebView2 allocation at the same scale. It is acquired during navigation, releases much of its resident footprint before the canonical checkpoint, and retains roughly 65 MiB after ten minutes. The second family retains roughly 39 MiB and grows after the canonical checkpoint. The third family is stable at roughly 18 MiB after the canonical route.

This does not identify the allocator owner. The families remain hypotheses until they are correlated with allocation stacks or a controlled workload transition. The next measurement should keep the same renderer alive while leaving and returning to a media-heavy route, then compare these three families and their post-return decay.

## Boundary

The run is not a production optimization and does not prove the 250 MiB target. The blank checkpoint used a different renderer PID and is a runtime control only. No renderer flags, media behavior, or Discord functionality were changed. The normal shell was relaunched after the diagnostic exited and remains on the no-`DiscordNative` path.
