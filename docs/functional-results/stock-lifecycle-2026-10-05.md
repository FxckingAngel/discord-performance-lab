# Stock lifecycle check

## Scope

This run covered only the automatable stock lifecycle items. It did not test account actions, messaging, notifications, voice, video, screen sharing, media, settings persistence, keyboard navigation, or integrations.

## Build and profile

- Client: Discord PTB 1.0.1223
- Executable: `C:\Users\notal\AppData\Local\DiscordPTB\app-1.0.1223\DiscordPTB.exe`
- Profile: stock launch with no extra command-line switch
- Date: 2026-10-05
- Operator: Korone

## Results

| Check | Result | Evidence |
| --- | --- | --- |
| Close the main window through the normal Windows close request | Pass for the close request; the process tree did not exit within the observation window | `CloseMainWindow()` returned `true`; the six-process tree remained live and required explicit cleanup |
| Confirm all child processes exit after normal close | Fail | The process tree remained live after 30 seconds; it was then stopped explicitly for test cleanup |
| Relaunch from the stock profile | Pass | `tools/Launch-DiscordPerformanceProfile.ps1 -Profile stock` started PID 32008 |
| Root process responds after relaunch | Pass | Root process responding at 15 seconds |
| Main window is present after relaunch | Pass | Window title was `Friends - Discord` |
| Stock launch remains free of the EcoQoS candidate switch | Pass | Root command line contained no `UseEcoQoSForBackgroundProcess` |

## Acceptance impact

The stock lifecycle result exposes a cleanup issue in the current test environment or client state: a graceful main-window close did not bring the Discord process tree down within 30 seconds. This is not evidence against EcoQoS specifically, but it blocks claiming lifecycle acceptance until the cause is understood and the candidate is tested against the same requirement.

EcoQoS showed the same behavior in a paired check: `CloseMainWindow()` returned `true`, the window title became empty, and all six processes remained live through 12 seconds of observation. The candidate was then force-cleaned for safety, and stock Discord was relaunched successfully with six processes, a responsive `Friends - Discord` window, and no EcoQoS switch.
