# Track B live memory refresh

Date: 2026-10-07

This was a read-only capture of the existing normal shell rooted at PID 39116.
Discord was not restarted and no shell or WebView2 settings were changed.

Artifact directory: `artifacts/track-b-live-memory-refresh-20261007/`

## Settled process-tree result

The capture produced 31 samples over an approximately 88-second observation,
with eight processes present in every sample.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Total working set | 806.72 MiB | 809.06 MiB |
| Private working set | 384.29 MiB | 385.99 MiB |
| Shareable working set | 422.82 MiB | 423.78 MiB |
| Private bytes | 591.39 MiB | 635.72 MiB |
| CPU | 0.067% | 0.336% |

## Per-role result

| Role | Working set median | Private working set median |
| --- | ---: | ---: |
| Renderer | 384.01 MiB | 282.41 MiB |
| Browser | 141.59 MiB | 34.45 MiB |
| GPU process | 109.16 MiB | 43.72 MiB |
| Native shell | 54.54 MiB | 7.17 MiB |
| Network service | 49.48 MiB | 8.49 MiB |
| Audio service | 27.70 MiB | 2.99 MiB |
| Storage service | 23.54 MiB | 2.94 MiB |
| Crashpad | 16.03 MiB | 1.33 MiB |

The renderer remains about 73.5% of the summed private working set. The
settled CPU median remains below the 0.2% target; its p95 is reported
separately and is not being optimized through generic scheduling changes.

## Renderer memory boundary

The paired read-only memory classification for renderer PID 28160 recorded:

- 381.23 MiB resident working set
- 283.77 MiB private writable resident
- 75.52 MiB image resident
- 20.85 MiB mapped resident
- 334.26 MiB committed private writable
- 50.50 MiB committed private writable that was not resident at the query

The resident categories are per-process classifications. They are not summed
as unique physical pages across processes, and reserved virtual address space
is excluded from the RAM KPI.

This refresh changes no optimization decision by itself. It confirms that the
renderer-native-memory attribution gate remains the next engineering target.
