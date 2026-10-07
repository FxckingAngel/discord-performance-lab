# Track B vanilla preload module map

Date: 2026-10-07  
Source: read-only extraction of the installed vanilla Discord PTB `mainScreenPreload.js`

## Purpose

The preload extractor now records the module ID and direct `IPCEvents.*` references for each `DiscordNative` group. This is static source evidence. It does not claim that every referenced operation runs during startup, and it does not expose any group to Track B.

## Sanitized module map

| Group | Preload module | Direct IPC references |
| --- | ---: | --- |
| `app` | 2100 | release channel, host version, build number, architecture, module versions, badge/dock actions, relaunch, default double-click action, frame-evictor pause state, preferred languages, UI direction, open-on-start setting |
| `window` | 5639 | flash frame, minimize, restore, maximize, focus, always-on-top, document PiP, always-on-top query, inactive show, blur, progress bar, fullscreen, close, minimum size, background throttling, frame rate, content protection, native handle, media source ID, focusable state, DevTools events |
| `desktopCapture` | 9425 | desktop-capturer source enumeration |
| `fileManager` | 3466 | show item, module/data/log/cache paths, create directory, open dialog, save dialog |
| `hardware` | 6955 | display count |
| `features` | 7064 | browser-feature query |
| `settings` | 6434 | no direct `IPCEvents.*` reference in the module body |

The complete sanitized output remains local under the ignored diagnostic artifacts. The extractor also records the static group-construction order and keeps runtime call sequence explicitly unset.

## Design consequence

The `window` group is not a small one-method contract. Exposing only minimize/maximize/close under a `DiscordNative.window` root would still present an incomplete desktop contract, matching the earlier white-page failure. `fileManager` and `desktopCapture` likewise require complete argument, return, cancellation, and error behavior before activation.

Track B therefore continues to keep the normal `DiscordNative` root absent. Individual capability implementations remain valid in isolated harnesses, but activation must wait for a coherent contract whose behavior is observed and backed by real native operations.

No authentication, authorization, network protocol, security state, or official-client behavior was changed.
