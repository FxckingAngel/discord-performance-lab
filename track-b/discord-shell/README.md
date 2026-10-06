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

## Scope of this milestone

The shell is only a feasibility prototype. It should establish whether the official web client can run in a smaller desktop container and provide a stock-versus-shell process-tree comparison. It is not an optimized client, an official Discord build, or a feature-complete replacement.

Track B measurements must count the complete WebView2 process tree, not only `KoroneDiscordShell.exe`. Use the existing benchmark tools with a separate process name and record startup, settled working set, private memory, CPU, GPU activity, process count, handles, threads, and responsiveness.
