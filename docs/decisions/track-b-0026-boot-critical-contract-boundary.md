# Track B decision 0026: boot-critical desktop contract boundary

Date: 2026-10-07

Track B must provide real desktop capabilities, but an incomplete `DiscordNative` object already produced an empty or white page. The production shell therefore remains on the known-good desktop user-agent identity with no partial Discord-native root object.

## Evidence available

The sanitized vanilla preload inventory contains 33 capability groups and 134 IPC event names. The short authenticated startup observation recorded zero calls through the existing diagnostic bridge. That observation was only 12 seconds long and does not prove that a group is unused during settings, notifications, uploads, voice, video, or screen sharing.

The inventory identifies possible contracts. It does not identify a safe boot-critical subset by itself. Property names and Electron-shaped objects are not sufficient evidence for exposing an API.

## Boundary

The boot-critical contract is defined as the smallest set of calls observed during Discord initialization that can each be backed by a tested native implementation. Until that evidence exists, the candidate set remains research-only.

For each candidate, the evidence record must contain:

| Field | Requirement |
|---|---|
| Official surface | Sanitized group and method name from the local vanilla preload inventory |
| Observed use | Method call observed during a controlled Discord scenario, with no arguments, return values, URLs, account data, or tokens recorded |
| Track B implementation | Real native behavior or an existing browser behavior shown equivalent for that method |
| Failure behavior | Cancellation, denied permission, unsupported operation, and native error behavior tested |
| Performance cost | Process, private working-set, CPU, and startup impact measured |
| Production status | Not exposed until the complete method group passes its functional tests |

## Current status by group

| Group | Evidence | Production decision |
|---|---|---|
| `window` | Track B already owns single-window minimize, maximize, restore, focus, and close behavior | Keep shell-native; do not expose a partial Discord-native root |
| `clipboard` | Browser clipboard exists; file, image, and mixed-content equivalence is unverified | Research only |
| `fileManager` | Browser picker/download events exist; full open, save, cancellation, and show-in-folder equivalence is unverified | Research only |
| `desktopCapture` | `getDisplayMedia()` is not equivalent to Electron source selection | Research only |
| notifications | No complete native contract has been observed and tested | Research only |
| media devices | Browser permission/device behavior exists, but Discord desktop parity is unverified | Research only |
| remaining preload groups | Inventory evidence only | Do not expose |

## Decision

Do not add a partial `DiscordNative` object to production Track B. Extend the sanitized method-call probe across one controlled scenario at a time, implement a complete native capability group behind an isolated diagnostic mode, and expose it only after behavior and performance tests pass. This keeps Discord's own frontend in charge of rendering and avoids making unsupported desktop behavior appear available.
