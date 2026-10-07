# Track B current minimized isolation

Date: 2026-10-07

This was a read-only 64-second measurement of the existing shell with its main window minimized, followed by restoration and a responsiveness check. The route and workload were not independently verified.

## Results

- Process count: 8
- Private working set: 414.07 MiB median, 467.60 MiB p95
- Private bytes: 553.90 MiB median, 606.99 MiB p95
- CPU: 0.07% median, 0.15% p95

Final private working set by role:

- Renderer: 309.61 MiB
- Browser: 39.22 MiB
- GPU: 34.86 MiB
- Native shell: 9.19 MiB
- Network service: 9.89 MiB
- Audio service: 3.30 MiB
- Storage service: 3.09 MiB
- Crashpad: 1.81 MiB

## Interpretation

Minimizing the shell reduced GPU and CPU activity, but it did not materially reduce the renderer's private resident memory. The renderer remained approximately 310 MiB private working set, so the 250 MiB foreground target still requires reducing retained renderer state or choosing a lighter rendering architecture. Minimized-only behavior is not a substitute for the foreground goal.

The raw capture is `artifacts/track-b-current-minimized-20261007/process-tree.json`.
