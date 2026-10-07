# Track A pristine reference: isolated login-screen diagnostic

Date: 2026-10-07

This is a secondary pristine-reference observation, not an authenticated same-route comparison. It uses the separately installed official stable Discord package at version 1.0.9260 with a dedicated profile. The active DiscordPTB installation, including its Vencord modifications, was not stopped, restarted, patched, or used for this capture.

## Package and isolation

- Channel: official stable Windows x64
- Version: 1.0.9260
- Executable: `<local Discord installation>`
- Profile: private `benchmarks/private/TrackB-DiscordVanillaDiagnostic/Profile`
- Login automation: not used
- Captured state: unauthenticated login screen
- Track B comparison build: 1.0.1223, so this is not a same-build control

The installed package contained the official `resources\app.asar` and `modules\discord_desktop_core-2\discord_desktop_core\core.asar`. A filename scan found no Vencord, BetterDiscord, patcher, or plugin paths. That scan is supporting evidence only; it is not a runtime proof of pristine behavior.

## Sanitized environment observation

The probe recorded only aggregate environment fields. It did not write page text, URLs, cookies, tokens, heap objects, or native object values.

- User agent: `discord/1.0.9260`, Chrome 148.0.7778.280, Electron 42.11.8
- Platform: `Win32`
- Login-screen viewport: 300x350 CSS pixels, outer 316x358, device-pixel ratio 1
- Media queries: hover and fine pointer true, reduced motion false, dark theme true
- Standard capabilities: notifications, media devices, camera/microphone capture, display capture, clipboard, file picker, downloads, drag/drop, and visual viewport were present
- `electron`, `process`, `module`, `require`, and `DiscordNative` were not present as page globals
- `chrome` was present; no DiscordNative capability groups were exposed

The small viewport is expected for the login-screen observation and must not be used as a performance or visual-parity result. A manual login and exact-route checkpoint is still required before this installation can serve as a pristine authenticated reference.

## Reproduction

Use `tools\Launch-TrackAPristineDiagnostic.ps1`. It launches only the isolated stable installation with the dedicated profile and a loopback diagnostic endpoint, then writes a sanitized environment report. Do not use it to automate login. Leave the client at the login screen for manual use when a checkpoint is needed.

Official provenance was resolved from [Discord's download page](https://discord.com/download) and its [official stable Windows installer endpoint](https://discord.com/api/downloads/distributions/app/installers/latest?arch=x64&channel=stable&platform=win). The downloaded installer and raw profile remain under the private benchmark directory and are not repository artifacts.
