# Track B renderer attribution pass: 2026-10-06

Status: local diagnostic evidence only. The route and workload were not independently verified, and this run is not an authenticated same-route acceptance result.

## Method

- Diagnostic shell: authenticated no-bridge mode with the local loopback CDP endpoint
- Duration: 60 seconds requested; process attribution recorded 71.58 seconds across 13 samples
- One renderer target was present
- Read-only CDP runtime and allocation sampling
- No heap snapshot was captured
- The diagnostic shell was closed normally and the regular shell was restored and observed responsive

## Process attribution

The diagnostic process-tree schema reports per-process MiB values. Summed values are retained here for comparison, but shareable working set is not unique physical memory.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 891.57 MiB | 1071.78 MiB |
| Summed private working set | 460.03 MiB | 649.66 MiB |
| Summed shareable working set | 429.67 MiB | 431.59 MiB |
| Summed private bytes | 657.40 MiB | 875.68 MiB |
| CPU | 0.197% | 1.031% |

The high spread reflects diagnostic startup and settling, so these values are not interchangeable with the 600-second normal-shell baseline.

The final process sample contained one renderer:

| Role | Private working set | Private bytes |
| --- | ---: | ---: |
| Renderer | 310.32 MiB | 347.00 MiB |
| GPU process | 40.84 MiB | 125.11 MiB |
| WebView2 browser | 39.38 MiB | 49.54 MiB |
| Network service | 9.95 MiB | 15.10 MiB |
| Native shell | 7.77 MiB | 11.30 MiB |
| Audio service | 3.43 MiB | 8.18 MiB |
| Storage service | 3.20 MiB | 7.77 MiB |
| Crashpad | 1.81 MiB | 3.03 MiB |

## Renderer runtime signals

| Signal | Value | Interpretation |
| --- | ---: | --- |
| V8 used heap | 61.22 MiB | Measured live JavaScript heap |
| V8 heap total | 71.91 MiB | V8 capacity reported by the renderer |
| Native sampled allocations | 44.92 MiB | Sampled allocation signal, not a resident-memory total |
| Native allocation samples | 1,393 | Diagnostic sample count |

The renderer's approximately 310 MiB private working set is not equivalent to its approximately 61 MiB live V8 heap. At least roughly 249 MiB remains outside the live V8-used figure in this sample. That remainder cannot yet be assigned to Blink, decoded media, compositor resources, code, or general Chromium native allocations without stronger category-specific evidence.

## Decision

No renderer behavior was changed. Do not add forced collection, working-set trimming, hardware-acceleration removal, or unmeasured runtime switches. The next attribution work should isolate the non-V8 remainder with local, aggregate-only diagnostics and retain per-PID process measurements.
