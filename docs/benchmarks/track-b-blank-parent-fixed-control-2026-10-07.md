# Track B corrected blank-runtime control: 2026-10-07

This diagnostic used the blank WebView2 mode after the process-tree parent-reuse fix. It did not load Discord or account content. The normal Track B shell was restored afterward, and official Discord was not touched.

Raw artifacts: `artifacts/track-b-blank-parent-fixed-retry2-20261007/`.

## Blank control

| Metric | Median | p95 |
| --- | ---: | ---: |
| Complete-tree private working set | 72.60 MiB | 73.58 MiB |
| Renderer private working set | 9.82 MiB | 10.03 MiB |
| Renderer private-writable resident | 8.09 MiB | final classification |
| Renderer image-backed resident | 33.79 MiB | final classification |
| Renderer mapped resident | 2.80 MiB | final classification |
| Process count | 7 | 7 |
| CPU | 0.000% median | not material in this short control |

The blank renderer's largest allocation family was approximately 3.41 MiB resident. Using the sanitized rank comparison against the earlier loaded renderer classification, the loaded top three rank groups add approximately **136.39 MiB** resident over the blank control. Rank comparison is not allocator ownership and the loaded and blank captures are separate processes, so this is a runtime-floor differential rather than a feature attribution.

The corrected control supports the existing conclusion that WebView2 itself is well below the 250 MiB target. The remaining gap is created by Discord-loaded state and still requires a manually verified route/workload comparison before optimization.
