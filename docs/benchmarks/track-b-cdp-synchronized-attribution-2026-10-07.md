# Track B synchronized CDP and process attribution

Date: 2026-10-07

This diagnostic restarted only Track B with `--diagnostic-authenticated-no-bridges`, enabled loopback CDP on port 9230, and measured the same diagnostic root while a 60-second CDP trace ran. The normal shell was restored afterward and remained responsive. Route and workload were not manually confirmed.

## Process capture

The diagnostic tracing environment added a ninth process, `utility/tracing.mojom.TracingService`. That process had a median private working set of 7.58 MiB and a p95 of 50.77 MiB. It must not be included in normal Track B acceptance comparisons.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Complete-tree private working set | 420.36 MiB | 466.00 MiB |
| Complete-tree private bytes | 610.08 MiB | 654.47 MiB |
| Complete-tree CPU | 0.065% | 0.897% |
| Process count | 9 | 9 |
| Renderer private working set | 299.09 MiB | 338.56 MiB |
| GPU private working set | 42.64 MiB | 44.57 MiB |

## CDP trace

The paired trace received 18,758 events with no reported data loss. It recorded approximately 37.6 `RunTask` events/sec, 13.1 `FunctionCall` events/sec, 0.033 `UpdateLayoutTree` events/sec, 0.083 layout events/sec, and 0.117 paint events/sec. Fifteen periodic memory-dump intervals were observed, but the exporter returned no byte-level memory-dump scalars.

The process and CDP captures overlap in time and use the same diagnostic shell, but the extra tracing service and unconfirmed route prevent this from serving as an acceptance baseline. It does establish that synchronized CDP and per-process sampling are technically possible.

No renderer behavior, Discord protocol, authentication, security state, media behavior, or official Discord installation was changed. Raw artifacts remain private under `artifacts/track-b-cdp-trace-sync-20261007/`.
