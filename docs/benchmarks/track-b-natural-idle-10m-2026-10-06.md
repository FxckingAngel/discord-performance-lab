# Track B natural idle observation

Date: 2026-10-06

This was a single 10-minute diagnostic run against the isolated unauthenticated `--diagnostic-discord` profile. It used the rooted process sampler with 30-second intervals and eight processes throughout. It is not an authenticated acceptance benchmark.

| Metric | Median | P95 | Minimum | Maximum |
| --- | ---: | ---: | ---: | ---: |
| Summed working set | 627.09 MiB | 661.28 MiB | 625.03 MiB | 712.53 MiB |
| Private working set | 221.95 MiB | 266.93 MiB | 221.18 MiB | 327.07 MiB |
| Private bytes / commit | 331.29 MiB | 365.53 MiB | 327.93 MiB | 473.47 MiB |
| Derived shareable working set | 404.35 MiB | 405.52 MiB | 385.46 MiB | 405.54 MiB |
| Total CPU | 0.072% | 0.072% | — | — |
| Process count | 8 | 8 | 8 | 8 |

The tree naturally declined from 473.47 MiB to 330.20 MiB private bytes over the run without forced GC or working-set trimming. At the final sample, the renderer held 166.93 MiB private bytes and 143.58 MiB private working set; the GPU held 83.28 MiB private bytes and 32.09 MiB private working set. The settled private-working-set median is below the approximately 250 MiB Track B target, but its p95 exceeds it and the profile was not authenticated or placed in a normal channel workload.

This result changes the next gate: repeat the same 10-minute natural-idle measurement after normal login and in the same static channel used for official Discord. Do not optimize against the unauthenticated route or claim the target is met from this run.
