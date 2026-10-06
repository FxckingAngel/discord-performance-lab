# Stock restart and startup baseline

Date: 2026-10-06

Discord PTB was deliberately restarted using the installed executable after the user authorized restart testing. The prior process tree was closed, the client was launched again, and the rooted tree was observed until three stable samples were collected.

| Field | Result |
| --- | ---: |
| Executable | `DiscordPTB.exe` 1.0.1223 |
| Root PID after restart | 24320 |
| Main window first seen | 1.314 seconds |
| Process tree first stable | 13.858 seconds |
| Stable sample count | 3 |
| Final process count | 6 |
| Final window | `@xoxo - Discord` |
| Final window responding | yes |
| Final memory-priority state | normal for all six roles |

The startup observer saw transient updater and helper-process counts of 5, 6, 8, and 7 before settling at six. The raw collector output is retained locally at `benchmarks/raw/stock-restart-current.json`.

The restart itself necessarily interrupted the process. A native UI observation confirming voice-session reconnection was not available in this run, so voice continuity after restart remains unverified. No low-memory or QoS candidate was applied.
