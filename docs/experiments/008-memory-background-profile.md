# Experiment 008: background memory-priority profile

## Status

Opt-in experimental profile; not accepted as the default launch mode.

## Scope

`Launch-DiscordPerformanceProfile.ps1 -Profile memory-low -BackgroundIdleConfirmed` starts the stock Discord executable and a hidden watcher. The watcher waits until the main window has appeared, applies low memory priority to the browser, crashpad, network utility, and renderer roles only while the window is minimized or hidden, and restores normal priority for the complete tree when the window is visible.

The GPU and audio roles remain normal during the background hint. The profile requires explicit idle confirmation because a minimized Discord window can still carry an active voice, video, or media session.

## Evidence

The underlying low-priority hint passed the five-percent resource gate in two short probes and one 45-second probe. The longer run reduced working-set median by 2.110%, working-set p95 by 2.768%, private-memory median by 1.948%, and private-memory p95 by 3.880%, with CPU effectively unchanged and six processes throughout.

The user observed no breakage during low-priority testing, but was not actively talking to another person. Low-priority voice, video, messaging, media, notification, accessibility, settings persistence, and cleanup remain unverified. The profile is therefore limited to opt-in background experimentation.

## Rollback

Restoring the window causes the watcher to set normal memory priority for all roles. The stock profile remains the default rollback path. If the watcher is stopped while Discord is minimized, run:

```powershell
.\tools\Set-DiscordProcessMemoryPriority.ps1 -RootPid 12345 -Priority normal
```
