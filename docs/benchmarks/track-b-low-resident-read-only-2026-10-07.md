# Track B low-resident read-only observation

Date: 2026-10-07

This was a read-only observation of the already-running normal Track B shell
rooted at PID 52076. It did not restart Track B or touch official Discord.

The route, authentication state, visible workload, and frontend readiness were
not manually confirmed. This is diagnostic variance evidence, not an
acceptance baseline or an optimization result.

Raw private evidence:

`artifacts/track-b-current-read-only-20261007.json`

The capture lasted 31.8 seconds, used four samples at roughly five-second
intervals, and contained eight processes in every sample.

| Metric | Observed range |
| --- | ---: |
| Complete-tree private working set | 267.07–271.25 MiB |
| Complete-tree working set | 365.14–370.07 MiB |
| Complete-tree private bytes | 661.5–711.1 MiB |
| CPU interval samples | 0.000%, 0.468%, 0.097% |

The final sample's private working-set ownership was:

| Process role | Private working set |
| --- | ---: |
| Renderer | 216.32 MiB |
| GPU process | 24.66 MiB |
| WebView browser | 20.14 MiB |
| Network service | 4.84 MiB |
| Native shell | 2.15 MiB |
| Audio service | 1.02 MiB |
| Storage service | 1.17 MiB |
| Crashpad | 0.70 MiB |

This state is close to the Track B private-resident target, but it cannot be
compared with the canonical authenticated baseline until route and workload
state are confirmed. The large difference from other read-only captures is
preserved as evidence of state or lifetime variance, not treated as a saving.
