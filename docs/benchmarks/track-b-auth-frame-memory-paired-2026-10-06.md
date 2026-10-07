# Track B authenticated frame and memory paired capture

This capture pairs the navigation-complete WebView2 process/frame snapshot with the same process-tree and per-PID resident-memory observation. It used the Release shell with the authenticated no-bridge diagnostic profile. The route and workload were not manually verified, so it is attribution evidence rather than an acceptance benchmark.

| Measure | Result |
| --- | ---: |
| WebView2 process count excluding crashpad | 5 |
| Renderer active associated frames | 2 |
| Complete-tree private working set | 464.5 MiB |
| Renderer private working set | 350.6 MiB |
| Renderer private writable resident | 344.1 MiB |
| Renderer private writable committed | 378.8 MiB |
| V8 used heap | 113.9 MiB |
| CPU in final sample | 0.283% |

The renderer has approximately 230 MiB of private writable resident memory beyond measured V8 used heap. Two active frames are present, but frame count alone does not explain the non-V8 renderer footprint. Further isolation must distinguish Discord-created DOM/application state from Blink, media, and other native allocations.

The paired local artifact is `artifacts/track-b-release-auth-frame-memory-paired-20261006/`.
