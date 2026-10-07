# Track B post-inventory-refresh reference

Date: 2026-10-07

This reference was captured from the rebuilt normal shell after adding the WebView2 process-inventory refresh. The route and workload were not changed by the instrumentation. The complete tree was sampled for 60 seconds with five-second intervals, followed by a read-only renderer virtual/resident classification.

| Metric | Result |
| --- | ---: |
| Complete-tree private working set median | 405.62 MiB |
| Complete-tree private bytes median | 568.79 MiB |
| Complete-tree CPU median | 0.097% |
| Renderer PID | 40684 |
| Renderer private-writable resident | 330.18 MiB |
| Three largest allocation-base groups | 81.32, 43.98, 22.97 MiB |

This does not establish an optimization result. It confirms that the reporting instrumentation does not itself account for the remaining memory gap. No Discord feature, media behavior, authentication, network behavior, or renderer scheduling was changed.
