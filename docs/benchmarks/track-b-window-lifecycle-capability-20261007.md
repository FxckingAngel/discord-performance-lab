# Track B native window-lifecycle capability

Date: 2026-10-07

This is a focused audit of the smallest native capability group already owned
by the Track B shell: window lifecycle and shell chrome. It does not add a
Discord frontend bridge, change Discord behavior, or touch the active official
Discord installation.

## Scope and decision

The shell can provide these behaviors directly through WinForms:

- custom titlebar and drag region;
- minimize;
- maximize and restore;
- close;
- tray show/restore and exit;
- single-instance launch with restore/focus of the existing shell.

These are genuine native shell behaviors. They are safe to keep enabled because
they do not require page JavaScript to receive a partial `DiscordNative` object.
They do not, by themselves, prove that Discord's frontend is using the same
desktop window contract as Electron.

`DiscordNative.window` remains diagnostic-only. The current diagnostic bridge
implements five message actions, but the locally observed official property
names include additional behavior such as fullscreen, blur, native handles,
frame-rate control, always-on-top, and content protection. The observed names
are not a complete contract, so exposing the five-action subset in the normal
shell would repeat the earlier partial-bridge risk.

## Compatibility boundary

| Surface | Native Track B implementation | Evidence | Normal shell status |
| --- | --- | --- | --- |
| Titlebar and drag region | Borderless WinForms form, native drag dispatch through `WM_NCLBUTTONDOWN` | `MainForm.cs`; titlebar diagnostic | Enabled as shell chrome |
| Minimize | Native `FormWindowState.Minimized` and titlebar button | Focused window-bridge probe passed | Enabled as shell behavior; page bridge disabled |
| Maximize/restore | Native `FormWindowState.Maximized`/`Normal` and titlebar button | Source audit; isolated diagnostic path exists | Enabled as shell behavior; frontend contract unverified |
| Close | Native form close and tray Exit action | Normal close paths in shell tests and diagnostic cleanup | Enabled as shell behavior |
| Tray restore | `NotifyIcon` menu and double-click restore | `MainForm.cs`; titlebar/tray diagnostic | Enabled as shell behavior |
| Single instance | Named local mutex, restore and foreground request | Shell README and smoke-test coverage | Enabled for ordinary launches |
| `DiscordNative.window` page object | Loopback WebView2 message bridge with five actions | Diagnostic-only bridge probe | Not exposed in normal mode |

## Focused validation

Command run against the isolated verified Track B executable:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Invoke-TrackBWindowBridgeStateTest.ps1 -ExecutablePath <verified-shell-path>
```

Result:

```json
{
  "result": "PASS",
  "capability": "DiscordNative.window",
  "actions": ["minimize", "restore"],
  "nativeStateObserved": true,
  "officialDiscordTouched": false
}
```

The probe used the separate `--diagnostic-window-bridge` mode and loopback CDP
port. The window became iconic after the minimize call, returned to a visible
state after restore, remained responsive, and closed through the normal path.
The result validates native dispatch and cleanup only. It does not validate
Discord's use of the object.

The existing shell-only titlebar/tray diagnostic measured a 72.71 MiB median
private working set and 0.013% median CPU across seven processes. That is a
blank-runtime shell integration measurement, not an authenticated Discord
parity or production optimization result.

## Verified facts

- The normal shell's page initialization path does not create `DiscordNative`.
- The audited desktop-style user-agent signal does not claim native methods.
- The diagnostic window bridge accepts only the five named actions and routes
  them through the native form.
- No authentication, authorization, entitlement, network protocol, security
  setting, or Discord frontend UI was changed.
- The active official/Vencord Discord process was not stopped, restarted, or
  modified.

## Unverified or diagnostic-only facts

- Discord's current frontend call contract for `DiscordNative.window` is not
  known. The official property-name observation is not sufficient evidence.
- Fullscreen, focus/blur, native handles, frame-rate control, always-on-top,
  content protection, and any desktop-specific window flags are unimplemented.
- Pixel-level titlebar/client-area parity with official Discord is unverified.
- Authenticated Discord use of any window group is unverified.

## Promotion rule

Keep the shell-owned window lifecycle enabled. Do not promote
`DiscordNative.window` to the normal page until a complete contract is derived
from behavior-level evidence and every exposed action has a real native
implementation, cleanup behavior, rollback switch, and authenticated
functional test. A smaller object that only happens to satisfy one observed
method is not a safe desktop compatibility layer.

This workstream is therefore `measured` for shell-owned native window behavior
and `diagnostic-only` for page-world Discord compatibility.

Evidence references:

- `track-b/discord-shell/MainForm.cs`
- `track-b/discord-shell/Program.cs`
- `tools/Invoke-TrackBWindowBridgeStateTest.ps1`
- `docs/benchmarks/track-b-titlebar-tray-diagnostic-2026-10-06.md`
- `docs/benchmarks/track-b-desktop-capability-audit-2026-10-07.md`
