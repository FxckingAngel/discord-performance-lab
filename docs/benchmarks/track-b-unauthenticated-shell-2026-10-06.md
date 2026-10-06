# Track B unauthenticated shell baseline

Date: 2026-10-06

This is a feasibility smoke result for `track-b/discord-shell`, not a stock comparison. The shell opened a responsive native window and created a WebView2 process tree using the installed Evergreen Runtime 154.0.4258.53. The WebView2 profile was separate from the official Discord desktop profile and was not logged in during this capture.

The rooted collector was corrected before this run to include all descendant process names. The 15-second capture had three samples and eight processes in every sample:

| Measure | Result |
| --- | ---: |
| Process tree | 8 |
| Process names | `KoroneDiscordShell.exe`, `msedgewebview2.exe` |
| First working set | 898.8 MiB |
| Last working set | 893.0 MiB |
| First private memory | 670.0 MiB |
| Last private memory | 655.9 MiB |
| Main window responding | yes |

Raw evidence is local at `benchmarks/raw/track-b/unauthenticated-shell-idle-15s-rooted.json` and remains ignored. The result cannot answer whether WebView2 beats stock Discord because it is a separate unauthenticated web profile and the settled duration is short. The next valid comparison requires the same logged-in account state, channel, window dimensions, display, network state, and settled duration on both applications.

The earlier one-process result was invalid for Track B because it omitted WebView2 descendants. The corrected rooted collector now follows every descendant of the supplied root PID, regardless of executable name.

The corrected startup run reported:

- first process-tree observation: 1.490 seconds;
- first responsive window: 1.496 seconds;
- stable process tree: 9 processes by 6.533 seconds;
- main window responsive: yes.

A later 30-second settled capture against the same unauthenticated profile held eight processes and measured median working set of 1,058.29 MiB and median private memory of 838.89 MiB. This is a baseline for the WebView2 host in its current state, not evidence that the architecture is lighter. The logged-in, same-channel stock comparison remains the decision gate.

## Follow-up rooted attribution

A later 30-second rooted capture was taken while the shell remained responsive. It produced six samples at five-second intervals and held eight processes throughout. The final sample measured 836.2 MiB working set and 557.7 MiB private memory for the full tree:

| Role | Working set | Private memory | CPU seconds since launch |
| --- | ---: | ---: | ---: |
| Native shell host | 60.1 MiB | 11.8 MiB | 0.31 |
| WebView2 browser | 155.3 MiB | 53.3 MiB | 2.77 |
| Renderer | 401.7 MiB | 340.5 MiB | 9.66 |
| GPU process | 110.3 MiB | 118.6 MiB | 1.50 |
| Network service | 48.9 MiB | 15.0 MiB | 1.47 |
| Storage service | 20.0 MiB | 7.6 MiB | 0.08 |
| Audio service | 26.5 MiB | 7.9 MiB | 0.11 |
| Crashpad | 13.5 MiB | 2.9 MiB | 0.05 |

This remains unauthenticated evidence. It shows that the current shell is well above the Track B target before optimization, with the renderer and GPU process accounting for most of the current private-memory footprint. It does not establish whether the same ownership persists after normal login and the required Discord workload.
