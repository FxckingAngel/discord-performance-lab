# Track B repeated blank WebView2 floor

Date: 2026-10-06

Three valid repetitions were run with the rebuilt Release shell using `--diagnostic-blank`, 10 seconds of settling, and 15 seconds of measurement at 5-second intervals. The normal shell was restored after each run.

Artifacts:

- `artifacts/track-b-release-blank-floor-rep-retry-20261006/`
- `artifacts/track-b-release-blank-floor-rep-2-valid-20261006/`
- `artifacts/track-b-release-blank-floor-rep-3-standalone-20261006/`

The failed first attempt on port 9230 produced no capture and is excluded.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 364.90 MiB | 375.79 MiB |
| Private working set | 74.05 MiB | 74.70 MiB |
| Private bytes | 145.64 MiB | 147.23 MiB |
| Total sampled CPU | 0.008% | 0.033% |

Each repetition ended at approximately 375 MiB summed working set, 74.5–74.9 MiB private working set, and 146.9–147.6 MiB private bytes. The result is a stable blank-shell floor, not an authenticated Discord result. It leaves substantial headroom under the 250 MiB private-working-set target for the shell itself, while confirming that the loaded Discord frontend remains the main memory question.
