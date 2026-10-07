# Track B window-lifecycle follow-up

Date: 2026-10-07

## Decision

The next desktop capability group remains shell-owned window lifecycle. It is
already backed by real WinForms behavior in `MainForm.cs`, so it can remain
enabled without adding an Electron-shaped global or a partial
`DiscordNative` object.

This is shell parity work, not proof that Discord's frontend recognizes an
Electron window contract. `DiscordNative.window` remains diagnostic-only.

## Sanitized capability matrix

| Capability | Native implementation | Current evidence | Normal-shell decision |
| --- | --- | --- | --- |
| Custom titlebar and drag region | Borderless WinForms form and native drag dispatch | Source audit and existing titlebar diagnostic | Enabled as shell chrome |
| Minimize | `FormWindowState.Minimized` and titlebar action | Isolated bridge sequence reached minimized state | Enabled as shell behavior; no page bridge |
| Maximize and restore | `FormWindowState.Maximized`/`Normal` and titlebar action | Source audit; restore path is exercised by the isolated bridge | Enabled as shell behavior; no page bridge |
| Close | Native form close and tray Exit action | Shell close path is implemented; helper cleanup has a harness limitation | Enabled, with cleanup follow-up required |
| Tray restore | `NotifyIcon` menu and double-click restore | Existing titlebar/tray diagnostic | Enabled as shell behavior |
| Single instance | Named mutex and restore/focus request | Existing smoke-test coverage | Enabled for ordinary launches |
| `DiscordNative.window` | Five-action diagnostic message bridge | Diagnostic-only minimize/restore path | Not exposed in normal mode |

## Focused verification

The following command was run against the isolated Review build:

```text
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\Invoke-TrackBWindowBridgeStateTest.ps1 -ExecutablePath <Review-build-path>
```

The diagnostic reached the native minimize and restore checks, but the test
failed while waiting for the diagnostic process to close normally:

```text
Window bridge probe did not close normally.
```

The shell smoke test showed the same existing lifecycle limitation:

```text
Smoke process 56644 did not exit after its normal close action.
```

Only the two exact diagnostic processes created from this worktree were
terminated during cleanup. The ordinary Track B shell and the official
Discord installation were not touched. The close failure is retained as a
test limitation; it is not reported as a full capability pass.

## Deliberately unimplemented

The following remain outside this capability group:

- `DiscordNative.window` in the normal page world;
- fullscreen, focus/blur, native handles, frame-rate control,
  always-on-top, and content-protection methods;
- clipboard, file dialogs, downloads, show-in-folder, notifications,
  permissions, global shortcuts, and screen capture bridges;
- any authentication, authorization, entitlement, network, or security
  behavior.

Those surfaces need their own complete native contracts and behavior-level
tests. No renderer behavior was changed for this report.

## Build and test results

- `dotnet build .\track-b\discord-shell\KoroneDiscordShell.csproj -c Review --no-restore`: passed with 0 errors; the existing WindowsBase version-conflict warning remains.
- `tools/Invoke-TrackBWindowBridgeStateTest.ps1`: failed at normal diagnostic shutdown after reaching the window-state checks.
- `tools/Test-TrackBShellSmoke.ps1 -SkipNormalSingleInstance`: failed at the same helper-process shutdown assertion.
