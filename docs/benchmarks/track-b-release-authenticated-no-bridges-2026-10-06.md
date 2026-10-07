# Track B rebuilt authenticated no-bridge capture

This diagnostic used the rebuilt Release shell with `--diagnostic-authenticated-no-bridges`. It reused the local Track B WebView2 profile and did not add a compatibility bridge, alter authentication, or change Discord network behavior. The route and workload were not manually verified, so this is attribution evidence rather than an acceptance benchmark.

| Metric | Result |
| --- | ---: |
| Process count | 8 |
| Summed working set | 872.2 MiB |
| Summed private working set | 443.1 MiB |
| Summed private bytes | 654.1 MiB |
| CPU in final sample | 0.252% |
| Renderer private working set | 328.0 MiB |
| Renderer private writable resident | 322.5 MiB |
| GPU resident | 113.8 MiB |
| V8 used heap | 107.6 MiB |
| DOM nodes | 6,212 |
| Documents | 14 |
| JavaScript listeners | 2,247 |

The renderer's measured private writable resident memory exceeds the measured V8 heap by approximately 215 MiB. The remaining renderer gap is therefore not explained by V8 live heap alone. It still needs feature-specific isolation before any renderer behavior is changed.

The local raw evidence is under `artifacts/track-b-release-auth-no-bridges-20261006/`. It includes the process-tree time series, aggregate CDP diagnostics, and per-PID resident classifications.
