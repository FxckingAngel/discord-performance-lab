# Experiment 007: background memory priority

## Status

Prototype utility; preliminary CPU signal observed, but low-priority performance and functional acceptance remain pending.

## Change

`tools/Set-DiscordProcessMemoryPriority.ps1` applies Windows process memory priority to one rooted Discord tree. It uses the supported `SetProcessInformation` `ProcessMemoryPriority` class. `normal` is the rollback/default value; `low` and `very-low` are experimental background hints.

`tools/Get-DiscordProcessMemoryPriority.ps1` reads the same rooted tree without changing process state. Use it to verify the effective hint before and after a test.

`tools/Invoke-DiscordMemoryPriorityExperiment.ps1` runs a paired rooted-tree measurement, applies the requested hint only after `-BackgroundIdleConfirmed`, and restores normal priority in a `finally` path. It refuses to start if the tree is not initially normal or if the rollback cannot be verified.

Memory priority is a hint to the Windows memory manager. It may cause lower-priority pages to be trimmed before normal pages, but it does not guarantee an immediate working-set reduction and may increase page faults when Discord becomes active again.

Example rollback:

```powershell
.\tools\Set-DiscordProcessMemoryPriority.ps1 -RootPid 12345 -Priority normal
```

## Boundary

The utility only changes process memory-priority hints for the selected rooted tree. It does not empty working sets, terminate processes, patch Discord, alter network behavior, or access account data. GPU and audio roles should remain normal in any future background experiment until media behavior is separately accepted.

## Acceptance plan

1. Establish paired stock and low-priority background-idle runs.
2. Measure working set, private memory, CPU, page faults, and wake-up responsiveness.
3. Repeat active text, media, voice, video, notification, accessibility, and cleanup checks.
4. Reject the hint if active-use latency or page faults regress, even if working set falls.

## Preliminary paired results

Two short rooted-tree probes were run on the installed stock Discord PTB process. Each probe measured stock first, applied low priority to the browser, crashpad, network utility, and renderer roles, preserved normal priority for the GPU and audio roles, measured again, and verified normal priority during rollback.

| Run | CPU median | Working-set median | Working-set p95 | Private-memory p95 | Processes | Gate |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 2.186% to 1.773% (-18.893%) | 1,341.77 to 1,348.52 MiB (+0.503%) | 1,349.50 to 1,352.80 MiB (+0.245%) | 1,118.41 to 1,060.92 MiB (-5.140%) | 6 to 6 | passed |
| 2 | 2.682% to 2.276% (-15.138%) | 1,369.54 to 1,368.70 MiB (-0.061%) | 1,372.88 to 1,380.73 MiB (+0.572%) | 1,118.33 to 1,109.51 MiB (-0.789%) | 6 to 6 | passed |

The CPU reduction repeated, but the memory signal was small and inconsistent. These were five-sample, roughly fifteen-second measurements rather than an acceptance run. No functional voice, video, messaging, media, notification, accessibility, or settings test was performed during the candidate windows, and voice reconnection after the preceding restart was not independently observed. The low-priority hint is therefore not an accepted default.

Raw evidence is retained locally under `benchmarks/raw/memory-priority-live/` and `benchmarks/raw/memory-priority-live-run2/`; those raw files are intentionally ignored by the repository.

## Source

- [Microsoft: SetProcessInformation](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-setprocessinformation)
- [Microsoft: MEMORY_PRIORITY_INFORMATION](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/ns-processthreadsapi-memory_priority_information)
