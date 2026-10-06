# Experiment 005: rooted process QoS control

## Status

Prototype utility; performance and functional acceptance pending.

## Change

`tools/Set-DiscordProcessQoS.ps1` applies either EcoQoS or system-managed process QoS to one Discord process tree. It uses the supported Windows `SetProcessInformation` API with `ProcessPowerThrottling` and does not modify Discord files, client protocol behavior, credentials, or account state.

Example rollback to system-managed scheduling:

```powershell
.\tools\Set-DiscordProcessQoS.ps1 -RootPid 12345 -Mode system-managed
```

## Boundary

The tool requires an explicit root PID and only targets that PID and its same-name descendants. It does not enumerate or change unrelated processes. The system-managed mode clears the explicit execution-speed control and returns policy selection to Windows.

## Acceptance plan

1. Run paired stock and QoS measurements with the rooted collector.
2. Repeat foreground, background-idle, voice, video, and media scenarios.
3. Reject the mode if responsiveness, calls, media, notifications, or cleanup regress.
4. Keep EcoQoS scoped to background work unless a foreground gate passes.

## Live rollback check

On 2026-10-06, the utility applied `system-managed` to the six observed descendants of Discord PTB root PID 32524. All six operations returned `applied`; the client remained stock, its main window remained responsive, and the rooted process count stayed at six. A five-second post-reset sample recorded 1,206.16 MiB median working set, 1,064.63 MiB median private memory, and 0.996% CPU. This validates the rollback operation only, not EcoQoS performance or foreground functionality.

## Live EcoQoS probe

On the same running client, EcoQoS was applied to all six descendants for one five-second foreground probe and then reset in a `finally` block. The probe measured 1,210.99 MiB median working set, 1,062.20 MiB median private memory, 1.484% CPU, and six processes. The post-reset stock sample measured 1,206.16 MiB, 1,064.63 MiB, 0.996% CPU, and six processes. These single short samples are not a paired acceptance run, but they provide no evidence of a foreground win and show a 49.0% higher CPU reading during the EcoQoS probe. EcoQoS remains restricted to the previously accepted background-idle scope.

## Source

- [Microsoft: SetProcessInformation](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-setprocessinformation)
- [Microsoft: Quality of Service](https://learn.microsoft.com/en-us/windows/win32/procthread/quality-of-service)
