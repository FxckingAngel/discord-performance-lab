# Track B Chromium trace checkpoint: 2026-10-06

This was a 60-second, loopback-only CDP trace using the authenticated diagnostic launch. The production shell was closed through its normal window-close path and restored after the trace. The probe recorded aggregate event names and durations only. It did not retain page text, URLs, cookies, tokens, scripts, heap objects, or raw trace events.

## Capture

- Duration: 60 seconds
- Events received: 9,726
- Data loss: none
- Raw aggregate result: `benchmarks/raw/track-b-cdp-trace-manual-ready-20261006.json`
- Production shell after restore: responsive; post-restore startup sample is not used as a settled benchmark

## Observed activity

| Event | Count | Approximate rate | Total duration |
| --- | ---: | ---: | ---: |
| `RunTask` | 1,405 | 23.4/s | 189.8 ms |
| `Edge_RunTask` | 1,645 | 27.4/s | 398.9 ms |
| `Major concurrent marking rescheduled` | 843 | 14.1/s | not exposed as a standalone duration |
| `V8.GC_MC_INCREMENTAL` | 834 | 13.9/s | 11.7 ms |
| `BlinkScheduler_PerformMicrotaskCheckpoint` | 361 | 6.0/s | 0.2 ms |
| `periodic_interval` | 13 | 0.2/s | not exposed as a standalone duration |
| `GlobalMemoryDump.Computation` | 16 | 0.27/s | 60.8 ms |

The trace also contained six major-concurrent-marking starts and 834 incremental-marking events. No `Paint`, `CompositeLayers`, `DrawFrame`, `Layout`, or `UpdateLayoutTree` events were present in the selected event summary during this window.

## Attribution boundary

This is evidence that V8 garbage-collection scheduling and general task wakeups are active in the sampled renderer state. It is not proof that GC is the sole source of the process CPU or that the activity is representative of every Discord route. The trace does not justify disabling GC, changing renderer isolation, or applying a Chromium switch. The next optimization experiment must correlate this trace with a repeated process-tree CPU/memory baseline and a functional check.
