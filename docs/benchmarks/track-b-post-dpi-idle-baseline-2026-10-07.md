# Track B post-DPI idle baseline

Date: 2026-10-07

This is a Track B-only measurement on the primary 1920x1080 monitor. The clean official reference remained on the separate TV and was not used to create this result.

| Metric | Result |
| --- | ---: |
| Samples | 5 over 30.5 seconds |
| Complete-tree process count | 8 |
| Private working set median | 465.35 MiB |
| Private working set range | 460.87–470.35 MiB |
| Total working set median | 858.93 MiB |
| Private bytes median | 665.60 MiB |
| Renderer private working set average | 358.97 MiB |
| Complete-tree CPU median | 0.307% |

The shell remained responsive. This does not meet the approximately 250 MiB and 0.2% settled-idle target. The renderer remains the dominant resident-memory owner, so further work should focus on lifecycle and native renderer attribution rather than display scaling or arbitrary runtime flags.

The raw process-tree artifact is private: `artifacts/track-b-post-dpi-baseline-20261007/process-tree.json`.
