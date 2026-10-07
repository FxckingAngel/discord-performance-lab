# Track B rebuilt authenticated CDP trace

This trace used the rebuilt Release shell with the authenticated no-bridge diagnostic profile. It enabled aggregate Blink, DevTools timeline, V8-GC, and Chromium memory-infra categories for 20 seconds after a short settle period. Raw trace events were discarded by the collector; the local artifact contains only sanitized counts and selected aggregate values.

| Measure | Result |
| --- | ---: |
| Trace events received | 141,111 |
| Memory-dump/periodic events | 15 |
| Trace data loss | No |
| Blink events | 11,003 |
| Layout-tree updates | 417 |
| Layout events | 56 |
| Paint events | 134 |
| V8-GC events | 3,511 |
| RunTask events | 25,170 |
| FunctionCall events | 504 |

The current aggregate parser did not find numeric scalar fields inside this WebView2 memory-dump payload shape. This artifact therefore provides workload-activity evidence, not byte-level native attribution. It does show that Blink/layout/paint activity is measurable and can be compared across manually prepared scenarios without publishing page data or heap objects.

Local artifact: `artifacts/track-b-release-auth-cdp-trace-20261006.json`.
