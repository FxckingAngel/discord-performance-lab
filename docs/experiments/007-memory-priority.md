# Experiment 007: background memory priority

## Status

Prototype utility; low-priority performance and functional acceptance pending.

## Change

`tools/Set-DiscordProcessMemoryPriority.ps1` applies Windows process memory priority to one rooted Discord tree. It uses the supported `SetProcessInformation` `ProcessMemoryPriority` class. `normal` is the rollback/default value; `low` and `very-low` are experimental background hints.

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

## Source

- [Microsoft: SetProcessInformation](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-setprocessinformation)
- [Microsoft: MEMORY_PRIORITY_INFORMATION](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/ns-processthreadsapi-memory_priority_information)
