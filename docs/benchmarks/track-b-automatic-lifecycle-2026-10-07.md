# Track B automatic lifecycle attribution: 2026-10-07

Status: unverified lifecycle diagnostic. This run used the new `-Automatic` mode of `Invoke-TrackBLifecycleAttribution.ps1` against the authenticated profile. No manual route or workload checkpoint was supplied. The official Discord installation was not touched.

## Checkpoints

| Timed checkpoint | Tree private WS | Tree private bytes | Renderer private WS | Renderer private bytes | DOM nodes | Documents |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Endpoint ready | 219.22 MiB | 303.23 MiB | 135.76 MiB | 154.50 MiB | 1,080 | 2 |
| 5 seconds | 219.07 MiB | 302.17 MiB | 135.25 MiB | 152.90 MiB | 1,084 | 2 |
| 15 seconds | 197.37 MiB | 276.82 MiB | 113.58 MiB | 127.51 MiB | 1,084 | 2 |
| 30 seconds | 174.14 MiB | 251.47 MiB | 97.04 MiB | 109.20 MiB | 1,084 | 2 |
| 60 seconds | 171.72 MiB | 249.37 MiB | 93.97 MiB | 106.11 MiB | 1,084 | 2 |
| 3 minutes | 170.18 MiB | 247.41 MiB | 92.82 MiB | 104.75 MiB | 1,084 | 2 |
| 5 minutes | 163.65 MiB | 242.05 MiB | 85.95 MiB | 98.96 MiB | 1,084 | 2 |

## Interpretation

The small, nearly unchanged document tree and one-page CDP target show that this run did not establish a fully initialized Discord application route. The five-minute 163.65 MiB private-working-set result is therefore a partial/loading diagnostic state, not a Track B performance result. It must not be compared with the normal authenticated shell or used to claim that the 250 MiB target has been reached.

The automatic mode is retained as a lifecycle tool for detecting when a real route begins allocating resources. A valid acceptance run still requires a manually confirmed account, exact route, window state, and workload.
