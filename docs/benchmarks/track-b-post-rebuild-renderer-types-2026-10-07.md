# Track B post-rebuild renderer memory classification

This read-only snapshot classified the current renderer process from the live Track B shell. It is not an authenticated acceptance benchmark because the route and workload were not manually verified. The shell was the existing `bin/Release` instance, not the separately rebuilt `bin/Verified` executable.

Artifact: `artifacts/track-b-post-rebuild-renderer-types-20261007/renderer.json`

Renderer PID: `23864`

| Category | MiB |
| --- | ---: |
| Total resident pages observed | 378.82 |
| Private writable resident | 280.75 |
| Private executable resident | 0.02 |
| Other private resident | 1.06 |
| Mapped resident | 21.56 |
| Image resident | 75.44 |
| Committed private writable | 329.25 |
| Committed mapped | 384.24 |
| Committed image | 369.62 |

The private writable resident category is consistent with the process-tree private-working-set measurement of roughly 277 MiB. Executable pages are negligible, so code/JIT pages are not a plausible explanation for the renderer gap. The next attribution work should split private writable memory by feature and allocation owner, especially Blink/DOM state, decoded media, compositor resources, and Chromium native allocations.

The resident totals are per-process observations and are not cross-process physical-page deduplicated. Reserved address space is excluded from the RAM figures.
