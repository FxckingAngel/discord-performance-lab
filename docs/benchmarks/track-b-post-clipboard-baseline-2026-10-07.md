# Track B post-clipboard implementation baseline

Date: 2026-10-07  
Mode: normal Track B shell; clipboard backend not exposed  
Artifact: `artifacts/track-b-post-clipboard-baseline-20261007/process-tree.json`

This 60-second observation checks that adding the isolated clipboard implementation did not change the normal shell. The shell was fully running from the authenticated WebView2 profile, but route readiness was not independently revalidated during this capture. It is diagnostic evidence, not the canonical acceptance baseline.

| Metric | Result |
| --- | ---: |
| Process count | 8 |
| Complete-tree private working set, median | 404.67 MiB |
| Complete-tree private working set, min/max | 401.90 / 413.63 MiB |
| Complete-tree CPU, median | 0.032% |
| Complete-tree CPU, min/max | 0.000 / 0.744% |

The earlier current baseline was 400.43 MiB private working set median over 120 seconds. This short observation is consistent with that range and does not demonstrate an optimization or regression. The clipboard backend remains unused, so it contributes no measured runtime cost in this mode.

The normal shell still exposes no `DiscordNative` object. The official Discord control was not modified.
