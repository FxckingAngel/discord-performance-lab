# Track B warmed CDP/process attribution: 2026-10-06

This controlled diagnostic closed the production shell normally, launched the authenticated diagnostic profile, allowed two minutes of warm-up, and then collected a 60-second CDP trace alongside a rooted process-tree sample. The production shell was restored normally afterward.

## Capture

- Diagnostic root PID: 43708
- Warm-up: approximately 120 seconds, excluded from the measured interval
- Measured interval: 64.2 seconds from the Windows sampler and 60 seconds from the CDP trace
- CDP events: 4,168
- CDP data loss: none
- Raw local artifacts: `benchmarks/raw/track-b-cdp-trace-warm-settled-20261006.json` and `benchmarks/raw/track-b-process-warm-settled-cdp-trace-20261006.json`
- Production shell after restore: PID 9764, responsive

## Trace result

| Event | Count | Approximate rate |
| --- | ---: | ---: |
| `RunTask` | 776 | 12.9/s |
| `IOHandler::OnIOCompleted` | 675 | 11.3/s |
| `SimpleWatcher::OnHandleReady` | 493 | 8.2/s |
| `Receive mojo message` | 381 | 6.4/s |
| `BlinkScheduler_PerformMicrotaskCheckpoint` | 13 | 0.22/s |
| `periodic_interval` | 13 | 0.22/s |
| Incremental V8 GC events | 0 | 0/s |
| Major concurrent marking starts | 0 | 0/s |
| Layout, paint, composite, or draw-frame events | 0 | 0/s |

## Diagnostic process result

| Metric | Median | p95 |
| --- | ---: | ---: |
| Summed working set | 571.06 MiB | not used for a gate |
| Private working set | 176.74 MiB | not used for a gate |
| Private bytes / commit | 277.96 MiB | 278.81 MiB |
| CPU | 0.000% | 0.304% |

## Interpretation

The warmed trace does not support sustained idle V8 garbage collection or compositor activity as the explanation for the remaining production-shell CPU. The dominant observed activity is task dispatch, I/O completion, Mojo messaging, and watcher wakeups. This is an attribution result, not an optimization result.

The diagnostic mode adds CDP and diagnostic-profile overhead, so its process totals are not comparable to the production acceptance gate. The production shell remains the only accepted resource target. No Chromium switch, GC setting, security change, or Discord frontend change was made.
