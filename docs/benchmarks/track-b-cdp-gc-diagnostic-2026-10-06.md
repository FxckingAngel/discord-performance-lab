# Track B diagnostic garbage-collection probe

Date: 2026-10-06

This was a diagnostic-only experiment against the isolated unauthenticated `--diagnostic-discord` profile. It called the local Chromium DevTools Protocol `HeapProfiler.collectGarbage` command once after an 8-second settle period, then measured the rooted process tree again. It did not run in normal Track B mode, did not trim working sets, and did not page memory out.

| Run | Renderer private before | Renderer private after | Renderer change | V8 used-heap change |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 236.8 MiB | 197.7 MiB | -39.2 MiB | -6.9 MiB |
| 2 | 230.8 MiB | 190.4 MiB | -40.4 MiB | -6.9 MiB |
| 3 | 232.5 MiB | 191.9 MiB | -40.6 MiB | -6.9 MiB |

The renderer-level result is repeatable, but it is not an optimization result. The process-tree private-memory change was less stable because browser-process memory also changed between the before and after samples. The fact that a small V8 reduction coincides with a larger renderer-private reduction does not identify the released pages as safe to collect during ordinary Discord idle, nor does it separate Blink, native Chromium, decoded media, or allocator behavior.

Decision: do not add forced garbage collection to the normal shell. The next diagnostic should compare naturally settled 10-minute idle runs and, if needed, use allocation/heap evidence to identify which retained objects make this memory collectible. Any future idle-GC experiment must measure responsiveness, wakeups, page faults, and feature behavior before it can be considered.
