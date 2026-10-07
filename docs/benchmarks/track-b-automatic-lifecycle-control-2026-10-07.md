# Track B automatic lifecycle control

Date: 2026-10-07  
Capture: `artifacts/track-b-lifecycle-automatic-20261007-031353`

## Status

This run completed normally through the five-minute checkpoint. It is an unverified control capture, not an authenticated Discord acceptance benchmark. Aggregate CDP diagnostics remained at one document and about 1,034 DOM nodes after the initial endpoint checkpoint, so the run did not reach the fully initialized Discord application state.

The raw process and CDP artifacts remain local and private. The clean official Discord control was not started, modified, or inspected by this run.

## Process and renderer trend

| Checkpoint | Tree private WS | Renderer private WS | GPU private WS | Renderer private-writable resident | Regions >=16 MiB | Largest allocation family | V8 used heap | DOM nodes | Documents |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Endpoint ready | 226.35 MiB | 146.12 MiB | 17.75 MiB | 142.91 MiB | 22.79 MiB | 27.79 MiB | 28.90 MiB | 1,034 | 2 |
| Startup, 5 s | 225.46 MiB | 145.57 MiB | 17.75 MiB | 118.65 MiB | 20.37 MiB | 27.75 MiB | 28.09 MiB | 1,034 | 1 |
| Startup, 15 s | 194.45 MiB | 114.64 MiB | 17.77 MiB | 111.94 MiB | 15.69 MiB | 25.04 MiB | 27.73 MiB | 1,034 | 1 |
| Startup, 30 s | 171.05 MiB | 97.28 MiB | 17.05 MiB | 94.55 MiB | 15.69 MiB | 21.20 MiB | 27.73 MiB | 1,034 | 1 |
| Startup, 60 s | 169.92 MiB | 95.46 MiB | 17.04 MiB | 92.73 MiB | 0 MiB | 20.91 MiB | 27.73 MiB | 1,034 | 1 |
| Settled, 3 min | 166.26 MiB | 93.03 MiB | 17.02 MiB | 90.30 MiB | 0 MiB | 21.16 MiB | 27.73 MiB | 1,034 | 1 |
| Settled, 5 min | 120.83 MiB | 65.87 MiB | 8.59 MiB | 63.34 MiB | 0 MiB | 19.48 MiB | 9.64 MiB | 1,034 | 1 |

## Interpretation

The largest allocation family and the renderer's private-writable resident footprint contracted during this unverified run. That establishes that these measurements can vary with page state and lifetime, but it does not identify a safe optimization or explain the normal authenticated state. The missing transition is the Discord application shell and authenticated route.

The 120.83 MiB five-minute result must not be compared directly with the normal Track B baseline or counted toward the 250 MiB goal. A future authenticated lifecycle capture needs a manual checkpoint or an explicit aggregate readiness predicate that confirms the Discord application is initialized before the settled measurements are accepted.

The normal Track B shell was restored after the capture and was responding.

