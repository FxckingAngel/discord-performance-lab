# Experiment 006: adaptive background QoS

## Status

Prototype utility; transition and functional acceptance pending.

## Change

`tools/Watch-DiscordBackgroundQoS.ps1` watches one observed Discord root PID. It applies the existing EcoQoS control only while the main window is minimized or has no window handle, and returns the process tree to system-managed QoS when the window is restored.

`tools/Launch-DiscordPerformanceProfile.ps1 -Profile adaptive` starts stock Discord and attaches this watcher automatically. The launcher reports both the Discord PID and watcher PID so the private profile can be inspected and stopped cleanly.

Run once to evaluate the current state:

```powershell
.\tools\Watch-DiscordBackgroundQoS.ps1 -RootPid 12345 -Once
```

Run continuously with a two-second poll interval:

```powershell
.\tools\Watch-DiscordBackgroundQoS.ps1 -RootPid 12345 -PollIntervalSeconds 2
```

## Boundary

The watcher changes only Windows process QoS for the selected Discord tree. It does not inject code, patch Discord files, alter network behavior, access credentials, or terminate processes. It deliberately treats a visible foreground window as system-managed so the previously observed foreground CPU regression is not promoted to normal active use.

## Acceptance plan

1. Validate foreground-to-background and background-to-foreground transitions with the rooted benchmark.
2. Repeat idle, text, media, voice, video, notifications, accessibility, and cleanup checks.
3. Confirm the watcher exits cleanly when the root process ends.
4. Keep the profile private until transition behavior and functional checks pass.

## Live transition check

On 2026-10-06, the visible Discord PTB window was minimized without restarting the client. A one-shot watcher run detected `minimizedOrHidden: true` and applied EcoQoS to all six descendants. The window was then restored; after the UI returned, the accessibility tree still exposed the active voice connection, camera control, and message composer. A second one-shot watcher run detected `minimizedOrHidden: false` and restored system-managed QoS. The client remained stock, responsive, and at six processes. This validates the transition mechanics, not yet the long-running resource or full functional gates.

## Minimized active-use probe

The same session was then measured while minimized with EcoQoS selected. Over 16.195 seconds, the rooted tree remained at six processes and recorded 1,127.63 MiB median working set, 1,133.00 MiB median private memory, and 0.999% CPU. Voice and media remained active during the probe. Because this was a single active-use sample without a paired stock run, it is transition evidence only and is not treated as a new performance improvement. Restoring the window and running the watcher again returned all six processes to system-managed QoS.

## Continuous loop check

The watcher was also run continuously with a one-second poll interval. It emitted `system-managed` while the window was visible, `ecoqos` after the window was minimized, and `system-managed` after the window was restored. The watcher was then stopped cleanly. A final profile check showed the stock command line, six processes, and a responsive main window.
