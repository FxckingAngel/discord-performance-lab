# Track B current minimized-state comparison

The dedicated minimized checkpoint measured the existing Release shell while its main window was minimized, then restored the window and verified responsiveness.

Final minimized sample:

| Metric | Result |
| --- | ---: |
| Process count | 8 |
| Total working set | 835.4 MiB |
| Private working set | 412.6 MiB |
| Private bytes | 551.3 MiB |
| CPU sample | 0.05% |

The result is diagnostic only because the route and workload were not manually verified. Relative to recent visible authenticated captures, minimizing reduces CPU and some resident memory, consistent with lower compositor/visibility activity. It does not approach the 250 MiB target and cannot substitute for a foreground settled-idle optimization.

The raw process-tree artifact is `artifacts/track-b-minimized-current-20261006/process-tree.json`.
