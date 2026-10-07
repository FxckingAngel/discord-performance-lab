# Track B current private-writable resident refresh

Date: 2026-10-06

Artifact directory: `artifacts/track-b-current-resident-refresh-20261006b/`

This read-only capture sampled the currently running Release shell after a short settled observation. It preserves one resident-memory classification file per PID.

| Role | Resident MiB | Private-writable resident MiB |
| --- | ---: | ---: |
| Native shell | 54.1 | 5.7 |
| WebView2 browser | 145.2 | 34.9 |
| Renderer | 442.4 | 335.9 |
| GPU process | 109.2 | 40.0 |
| Network utility | 50.1 | 8.1 |
| Storage utility | 23.8 | 1.8 |
| Audio utility | 28.1 | 1.7 |
| Crashpad | 16.4 | 0.9 |
| Complete tree | 869.4 | 429.0 |

The complete tree had 526.6 MiB of committed private-writable virtual memory in the same per-PID classification. No private-writable resident pages were marked shared in this capture. The renderer's private-writable resident category is therefore the main current attribution target, rather than a shared-page accounting artifact.

This is still a classification boundary, not a byte-perfect allocator map. It does not identify which native subsystem owns each private page, and it does not prove that the complete tree's unique physical footprint is 429.0 MiB. V8 heap measurements and feature-scenario deltas remain required before changing the renderer or claiming a savings opportunity.
