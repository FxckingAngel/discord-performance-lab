# Track B active-text diagnostic capture

Date: 2026-10-07

Artifact: `artifacts/track-b-feature-active-text-unverified-20261007`

The process-tree and per-PID resident-memory capture completed on the current
Track B shell. Manual route confirmation was intentionally skipped, so this is
not an active-text acceptance result and must not be compared as a confirmed
workload against official Discord.

## Final sample

| Metric | Value |
| --- | ---: |
| Processes | 8 |
| Complete-tree private working set | 453.13 MiB |
| Renderer private working set | 338.79 MiB |
| GPU private working set | 38.68 MiB |
| Root identity | Stable |
| Per-PID resident captures | 8 / 8 |
| Functional status | UNTESTED |

The capture confirms that the active-workload measurement path preserves the
root PID, process creation time, executable path, and individual helper roles.
It does not establish that typing, scrolling, media, or a specific Discord
route was active during the sample.

No Discord behavior was changed, and the official reference client was not
touched.
