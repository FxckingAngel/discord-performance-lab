# Track B profile diagnostic

Date: 2026-10-06

## Scope and limitation

The existing WebView2 profile was opened with `--diagnostic-authenticated` and inspected only through aggregate CDP diagnostics. The profile produced a real Discord document with 972 DOM nodes, 671 resources, one frame, 18 JavaScript event listeners, and 28.56 MiB of used V8 heap.

These aggregates do not prove that an account session is active. No page text, URL, cookies, tokens, or profile contents were read. The result is therefore a profile-load diagnostic, not the authenticated same-account acceptance benchmark.

## Full-tree observation

The process tree was sampled for approximately 35 seconds after startup.

| Metric | Median | P95 | Minimum | Maximum |
| --- | ---: | ---: | ---: | ---: |
| Summed working set | 531.06 MiB | 546.22 MiB | 531.05 MiB | 546.34 MiB |
| Private working set | 184.59 MiB | 206.37 MiB | 184.57 MiB | 208.50 MiB |
| Private bytes / commit | 262.82 MiB | 290.30 MiB | 262.80 MiB | 293.54 MiB |
| Shareable working set | 346.46 MiB | 346.48 MiB | 337.37 MiB | 346.48 MiB |
| Total CPU | 0.024% | 0.024% | - | - |
| Process count | 7 | 7 | - | - |

The private working-set result is near the 250 MiB design target, while the ordinary summed working-set result remains above the minimum gate. Because account state is unconfirmed, this evidence cannot be used to claim Track B success.

Raw CDP and process-tree data remain under `benchmarks/raw/` and are not published.
