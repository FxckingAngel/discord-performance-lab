# Track B automatic lifecycle capture

Date: 2026-10-07  
Mode: automatic-unverified  
Artifact: `artifacts/track-b-lifecycle-debug6-20261007`

This capture validates the lifecycle runner and records how the fully initialized shell changes from startup to five minutes. It is diagnostic evidence only. The route and workload were not manually confirmed, so these numbers are not the canonical authenticated static-route acceptance baseline.

The runner completed all seven checkpoints with `result=PASS`. Application readiness was false at the first endpoint check and true from the five-second checkpoint onward. The renderer PID remained stable at `3628` for the complete capture. The process inventory settled at eight processes.

| Checkpoint | Tree private WS | Renderer private WS | Tree private bytes | Renderer private bytes | CPU median | V8 used |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| endpoint-ready | 566.12 MiB | 422.97 MiB | 889.03 MiB | 549.89 MiB | 2.878% | 70.735 MiB |
| startup-5s | 611.13 MiB | 492.61 MiB | 782.00 MiB | 548.12 MiB | 0.557% | 113.932 MiB |
| startup-15s | 460.53 MiB | 343.93 MiB | 594.23 MiB | 391.49 MiB | 0.539% | 101.151 MiB |
| startup-30s | 428.10 MiB | 312.04 MiB | 618.47 MiB | 356.03 MiB | 0.642% | 103.999 MiB |
| startup-60s | 417.94 MiB | 304.64 MiB | 554.60 MiB | 353.62 MiB | 0.475% | 106.457 MiB |
| settled-3m | 417.14 MiB | 301.42 MiB | 595.89 MiB | 351.11 MiB | 0.961% | 94.485 MiB |
| settled-5m | 412.31 MiB | 293.87 MiB | 644.40 MiB | 344.99 MiB | 0.345% | 92.103 MiB |

Additional settled observations:

- DOM nodes: approximately 4,627
- Frames: 2
- Image elements: 149
- Video elements: 3
- Canvas elements: 4
- Route class: `discord-app` during early startup and `discord-channels` after initialization

## Interpretation

The capture shows a large renderer drop after the initial application load: 492.61 MiB at five seconds to 293.87 MiB at five minutes. That supports lifecycle attribution as the next memory investigation, but it does not identify an owner or prove that the retained state is reclaimable. No renderer behavior was changed and no optimization is accepted from this run.

The next valid comparison remains a manually confirmed, fully initialized route with repeated measurements. Native allocation families must be compared against that fixed state before an optimization is attempted.

Official Discord was not modified or used as a mutable test target.
