# Track B live settled capture: 600 seconds

Date: 2026-10-06

Status: diagnostic evidence only. The route and workload were not independently verified during this capture, so this is not an authenticated same-route acceptance result.

## Capture

- Source: `artifacts/track-b-live-settled-600s-20261006-164352.json`
- Sampler duration: 600.274 seconds
- Samples: 55
- Interval: 10 seconds
- Process count: 8
- Shell remained running throughout the capture
- No runtime flags or application changes were made for this run

The sampler reports shared working set as a derived value (`total - private`) because a native Windows shared-working-set counter is not exposed by the current sampler. It must not be interpreted as unique physical memory.

## Complete-tree results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Total working set | 825.17 MiB | 834.46 MiB |
| Private working set | 382.72 MiB | 391.91 MiB |
| Derived shareable working set | 444.92 MiB | 445.37 MiB |
| Private bytes / commit | 597.31 MiB | 629.36 MiB |
| CPU | 0.135439% | 0.461256% |

CPU meets the settled-idle median criterion of at most 0.2%. The p95 is reported separately and is not used to redefine that criterion.

## Per-role private working set

| Role | Median | P95 |
| --- | ---: | ---: |
| Renderer | 280.92 MiB | 289.79 MiB |
| GPU process | 41.80 MiB | 43.97 MiB |
| WebView2 browser | 35.46 MiB | 35.73 MiB |
| Network service | 8.96 MiB | 9.27 MiB |
| Native shell | 7.31 MiB | 7.34 MiB |
| Audio service | 3.03 MiB | 3.10 MiB |
| Storage service | 2.94 MiB | 3.04 MiB |
| Crashpad | 1.26 MiB | 1.34 MiB |

The renderer is the largest measured private-resident category. Reaching the complete-tree target while the other roles remain near these values would require reducing renderer private working set substantially below the current 280.92 MiB median, toward the existing 140–150 MiB renderer subgoal.

## Decision

Keep the known-good shell and current rollback path unchanged. Do not pursue generic scheduling or browser switches from this result. The next work is renderer attribution: compare renderer private resident memory with V8 live heap, Blink/DOM state, decoded media, compositor resources, caches, and other native allocations. Any heap snapshots or detailed diagnostics remain local because they may contain Discord content.
