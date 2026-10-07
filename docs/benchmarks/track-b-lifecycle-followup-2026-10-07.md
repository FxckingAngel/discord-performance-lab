# Track B lifecycle follow-up

This automatic run used the current diagnostic authenticated shell and recorded synchronized process-tree, CDP, and renderer virtual-memory checkpoints. It is attribution evidence only. The route and workload were not manually verified, so it is not an authenticated acceptance benchmark or an optimization result.

| Checkpoint | Tree private WS median | Renderer private WS median | Renderer private bytes median | V8 used | DOM nodes | Frames | Image/video/canvas elements |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Endpoint ready | 242.69 MiB | 160.66 MiB | 192.39 MiB | 28.40 MiB | 1,035 | 1 | 0 / 0 / 0 |
| 5 seconds | 242.43 MiB | 160.06 MiB | 179.08 MiB | 29.48 MiB | 1,036 | 2 | 0 / 0 / 0 |
| 15 seconds | 202.08 MiB | 119.95 MiB | 134.06 MiB | 29.11 MiB | 1,036 | 2 | 0 / 0 / 0 |
| 30 seconds | 177.74 MiB | 100.41 MiB | 112.41 MiB | 29.11 MiB | 1,036 | 2 | 0 / 0 / 0 |
| 60 seconds | 178.65 MiB | 101.39 MiB | 114.02 MiB | 29.11 MiB | 1,036 | 2 | 0 / 0 / 0 |
| 3 minutes | 172.96 MiB | 95.60 MiB | 107.57 MiB | 29.11 MiB | 1,036 | 2 | 0 / 0 / 0 |
| 5 minutes | 166.05 MiB | 88.34 MiB | 100.50 MiB | 29.11 MiB | 1,036 | 2 | 0 / 0 / 0 |

The renderer private-writable resident classification fell from 157.61 MiB at endpoint readiness to 85.59 MiB at five minutes while committed private-writable memory fell from 170.05 MiB to 90.43 MiB. This is a startup/profile-state lifecycle observation, not evidence that normal Discord can settle at this footprint.

The absence of image, video, and canvas elements and the very small stable DOM show that this run did not reach the fully initialized Discord workload required by Track B acceptance. The result must not be used to claim progress toward the approximately 250 MiB target. The next valid memory comparison still requires a manually confirmed authenticated static route, then the same route held through the settle window.

Raw process, CDP, and virtual-memory artifacts remain local under `artifacts/track-b-lifecycle-followup-20261007`.
