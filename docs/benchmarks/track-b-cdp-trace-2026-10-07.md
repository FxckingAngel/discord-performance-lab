# Track B synchronized CDP diagnostic

Date: 2026-10-07

This was a 60-second CDP tracing run using the authenticated no-bridge diagnostic shell after a 60-second settle period. The diagnostic shell was closed normally afterward and the ordinary Track B shell was restored. The route and workload were not manually confirmed, so this is diagnostic evidence only.

The trace received 88,732 events with no reported data loss. Raw trace data remains private under `artifacts/track-b-cdp-trace-20261007.json`.

## Sanitized aggregate findings

| Signal | Count or rate |
| --- | ---: |
| `RunTask` | 9,846 events, 164.1/sec |
| `FunctionCall` | 2,406 events, 40.1/sec |
| `AnimationFrame` | 816 events, approximately 13.6/sec |
| `UpdateLayoutTree` | 111 events, 1.85/sec |
| `Paint` | 111 events, 1.85/sec |
| `TimerFire` | 429 events, approximately 7.2/sec |
| `BlinkScheduler_PerformMicrotaskCheckpoint` | 3,216 events |
| Memory-dump events | 15 periodic samples |

The trace also contained repeated Blink style/layout, compositor-input, paint-artifact, GPU-task, timer, animation, and incremental V8 garbage-collection events. The trace exporter did not return memory-dump scalar values, so it does not provide a byte-level V8 or native-memory total.

## Interpretation

This gives a concrete wakeup and rendering baseline for the diagnostic state. It does not prove that any of these activities are unnecessary or safe to suppress. Visible animations, notifications, media, voice, video, and screen sharing remain protected functionality. No renderer behavior was changed from this trace.

The next useful comparison is the same CDP trace against a manually confirmed static route and then a media-heavy route, paired with per-PID private working-set and page-fault samples. Only differential activity that is both repeatable and functionally unnecessary should become an optimization candidate.

The trace used loopback CDP only, did not publish page content, heap objects, account data, tokens, command lines, or raw trace data, and did not modify official Discord.
