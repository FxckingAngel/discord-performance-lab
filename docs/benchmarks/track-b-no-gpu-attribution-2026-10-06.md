# Track B no-GPU attribution control

Date: 2026-10-06

This was a diagnostic-only control against the authenticated Track B profile. It used the WebView2 `WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS=--disable-gpu` environment override and the no-bridge diagnostic mode. The normal shell was stopped only for this isolated process-tree comparison and was restored afterward.

Microsoft documents `AdditionalBrowserArguments` and the equivalent environment override as diagnostic ways to pass WebView2 browser flags. The flag was not added to the shell source or normal launch path.

## Results

| Metric | Normal hardware acceleration | No-GPU diagnostic |
| --- | ---: | ---: |
| Total private bytes median | 706.18 MiB | 489.20 MiB |
| Total private working set median | 433.84 MiB | 414.32 MiB |
| Total working set median | 856.22 MiB | 840.87 MiB |
| Total CPU | 0.226% | 0.468% |
| Renderer private bytes median | 379.31 MiB | 371.71 MiB |
| GPU-process private bytes median | 212.33 MiB | 17.16 MiB |
| Process count | 8 | 8 |

The no-GPU run reduced committed/private GPU allocation substantially, but reduced private resident working set by only about 19.5 MiB and doubled measured idle CPU. It therefore does not satisfy the Track B requirements and is not an optimization candidate. Hardware acceleration remains enabled in the normal shell.

## Decision

The control confirms that GPU-related allocations explain much of the private-bytes gap but not the resident-memory gap. The next useful work must reduce resident renderer/frontend/native allocations while preserving hardware acceleration. No working-set trimming, paging, or GPU disablement was added.

## Inputs

- `benchmarks/raw/track-b-normal-no-bridges-settled-10min-summary-20261006.json`
- `benchmarks/raw/track-b-no-gpu-diagnostic-120s-summary-20261006.json`
- Microsoft WebView2 browser flags documentation: https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/webview-features-flags
