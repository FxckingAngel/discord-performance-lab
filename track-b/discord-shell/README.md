# Korone's Discord Shell prototype

This is the first Track B proof of concept. It is a native Windows WinForms executable that hosts Discord's official web application in the installed Microsoft WebView2 Runtime.

The prototype deliberately has no native host bridge, protocol interception, account automation, injected scripts, or Discord-specific network handling. It uses a separate WebView2 user-data folder under `%LOCALAPPDATA%\\KoroneDiscordShell\\WebView2UserData` so it does not reuse or modify the official Discord desktop profile.

## Build

From the repository root, with the local SDK installed:

```powershell
.\\.tools\\dotnet\\dotnet.exe restore .\\track-b\\discord-shell\\KoroneDiscordShell.csproj
.\\.tools\\dotnet\\dotnet.exe build .\\track-b\\discord-shell\\KoroneDiscordShell.csproj --configuration Release --no-restore
```

The machine must have the WebView2 Runtime installed. The first run uses the normal Discord web login flow. It does not import Discord desktop cookies or tokens.

For runtime attribution only, `KoroneDiscordShell.exe --diagnostic-blank` opens `about:blank` in a separate WebView2 user-data folder. This mode does not load Discord and must not be used as an application performance result. It estimates the shell and WebView2 runtime floor against the normal Discord URL. Diagnostic blank mode exposes only loopback CDP port 9223 for the sanitized environment probe and is not part of the normal shell.

For a separate unauthenticated environment probe against the actual Discord route, use `KoroneDiscordShell.exe --diagnostic-discord`. It uses a separate `EnvironmentProbeUserData` profile and loopback CDP port 9224. It must not be used to transfer credentials or claim a logged-in performance result.

For a diagnostic-only UA experiment, use `KoroneDiscordShell.exe --diagnostic-official-ua`. It uses a separate `UserAgentProbeUserData` profile, reports the observed official Discord UA, and exposes loopback CDP port 9225. This does not add `DiscordNative` or any native capability and is not accepted as a desktop compatibility implementation.

For the first native capability test, use `KoroneDiscordShell.exe --diagnostic-window-bridge`. It uses a separate `WindowBridgeProbeUserData` profile and loopback CDP port 9226. Only native window actions are exposed, and every message is restricted to the five implemented actions. This mode is diagnostic until behavior and resource cost are accepted.

For the read-only display capability test, use `KoroneDiscordShell.exe --diagnostic-hardware-bridge`. It uses a separate `HardwareBridgeProbeUserData` profile, loads a local in-memory blank document, and exposes loopback CDP port 9227. It exposes only `DiscordNative.hardware.getDisplayCount`, backed by the actual Windows display inventory. This mode is diagnostic until Discord feature use and resource cost are accepted.

For a private login-state check, close the ordinary shell first and use `KoroneDiscordShell.exe --diagnostic-authenticated`. It reuses the normal `WebView2UserData` profile, exposes loopback CDP port 9228, and is intended only for sanitized aggregate diagnostics or a private screenshot. Do not publish screenshots or raw profile data from this mode.

## Scope of this milestone

The shell is only a feasibility prototype. It should establish whether the official web client can run in a smaller desktop container and provide a stock-versus-shell process-tree comparison. It is not an optimized client, an official Discord build, or a feature-complete replacement.

Track B measurements must count the complete WebView2 process tree, not only `KoroneDiscordShell.exe`. Use the existing benchmark tools with a separate process name and record startup, settled working set, private memory, CPU, GPU activity, process count, handles, threads, and responsiveness.
