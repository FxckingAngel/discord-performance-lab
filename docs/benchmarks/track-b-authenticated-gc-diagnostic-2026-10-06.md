# Track B authenticated garbage-collection diagnostic: 2026-10-06

This was a diagnostic-only probe against the authenticated WebView2 profile. It invoked `HeapProfiler.collectGarbage` three times and measured the rooted process tree plus virtual-memory categories before and after each invocation. The production shell was not used for the probe and was restored afterward.

## Results

| Run | V8 used heap released | Renderer private bytes | Renderer private committed | Renderer writable private committed |
| --- | ---: | ---: | ---: | ---: |
| 1 | 0.54 MiB | 134.50 -> 133.31 MiB | 123.66 -> 122.48 MiB | 122.08 -> 120.90 MiB |
| 2 | approximately 0 MiB | 133.31 -> 133.31 MiB | 122.48 -> 122.48 MiB | 120.90 -> 120.90 MiB |
| 3 | approximately 0 MiB | 133.31 -> 133.31 MiB | 122.48 -> 122.48 MiB | 120.90 -> 120.90 MiB |

The complete diagnostic tree moved from 275.39 MiB to 274.43 MiB in the first run and then remained effectively unchanged. These diagnostic totals are not production acceptance measurements because the CDP diagnostic launch has additional overhead.

Raw local artifacts:

- `artifacts/gc-auth-heap-1-20261006.json` through `gc-auth-heap-3-20261006.json`;
- matching `gc-auth-before-*` and `gc-auth-after-*` virtual-memory snapshots.

## Decision

The authenticated renderer does not have a large immediately collectible V8 heap that can explain the approximately 5 MiB production private-bytes near miss. Do not add forced collection to the normal shell. The remaining writable renderer allocation is likely Blink/native/runtime state or retained workload state and needs a different allocation owner before any optimization is attempted.
