# Stock active voice-session baseline

Date: 2026-10-06

This is a read-only rooted process-tree sample from the installed Discord PTB client while the user's voice session was active. Discord was not restarted or modified.

| Field | Result |
| --- | ---: |
| Root PID | 32524 |
| Duration | 31.471 seconds |
| Samples | 6 |
| Process count | 6 in every sample |
| Working set median | 1,058.68 MiB |
| Working set p95 | 1,127.86 MiB |
| Private memory median | 1,092.12 MiB |
| Private memory p95 | 1,152.23 MiB |
| CPU median | 2.416% |
| CPU p95 | 2.844% |

The rooted roles were browser, crashpad-handler, GPU process, network utility, renderer, and audio utility. The raw collector output is retained locally at `benchmarks/raw/stock-active-voice-current.json`; raw benchmark files are local evidence and are not committed by the repository's ignore rules.

This baseline is observational evidence only. It does not establish that the six-process layout is reducible or that a candidate profile is safe for voice, video, messaging, or other Discord functions.
