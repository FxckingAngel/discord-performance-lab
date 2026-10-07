# Track B renderer lifecycle attribution

Date: 2026-10-07

Status: automatic, unverified diagnostic. The route was not manually held constant, so these values cannot serve as the authenticated acceptance baseline.

The current Release shell was measured from endpoint creation through five minutes settled. The same renderer PID, 38260, persisted across every checkpoint after startup.

| Checkpoint | Application ready | Full-tree private working set | Renderer private working set | V8 used | DOM nodes | Images | Videos | CPU median |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Endpoint ready | No | 421.05 MiB | 330.00 MiB | 9.30 MiB | 1,034 | 0 | 0 | 3.944% |
| Startup 5 seconds | Yes | 557.67 MiB | 441.71 MiB | 98.33 MiB | 4,494 | 128 | 3 | 0.397% |
| Startup 15 seconds | Yes | 435.14 MiB | 321.97 MiB | 95.53 MiB | 4,494 | 128 | 3 | 0.671% |
| Startup 30 seconds | Yes | 413.00 MiB | 303.27 MiB | 101.44 MiB | 4,505 | 130 | 3 | 0.287% |
| Startup 60 seconds | Yes | 396.60 MiB | 286.87 MiB | 100.36 MiB | 4,505 | 130 | 3 | 0.591% |
| Settled 3 minutes | Yes | 392.49 MiB | 277.88 MiB | 102.48 MiB | 4,505 | 130 | 3 | 0.430% |
| Settled 5 minutes | Yes | 389.77 MiB | 279.39 MiB | 85.01 MiB | 4,515 | 130 | 3 | 0.431% |

The important separation is between renderer private resident memory and V8 heap. At five minutes, roughly 194 MiB of renderer private working set is outside the measured V8 heap. This supports continuing native/Blink/compositor attribution rather than treating the whole renderer as JavaScript memory. The five-minute full-tree result is also well above the 250 MiB design target, and its CPU median is above the 0.2% target, but neither is accepted because the route and workload were not manually verified.

The endpoint checkpoint is intentionally excluded from workload claims because the application was not ready. The normal shell was relaunched after capture, and the official Discord reference was not touched.
