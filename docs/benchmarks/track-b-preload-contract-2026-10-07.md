# Track B read-only vanilla preload contract

Date: 2026-10-07  
Source: the locally installed Discord PTB `discord_desktop_core/core.asar`, inspected without changing the official client or its files.

The extracted `mainScreenPreload.js` contains a `DiscordNative` initializer with 33 groups and 134 named IPC event references. The sanitized contract is retained locally at `artifacts/discord-preload-contract-20261007.json`; the raw preload was removed after extraction.

The groups include `app`, `clipboard`, `desktopCapture`, `features`, `fileManager`, `hardware`, `notifications`, `powerMonitor`, `safeStorage`, `settings`, `tracing`, and `window`, as well as security-sensitive or unrelated surfaces such as generic IPC, native modules, process controls, crash reporting, WebAuthn, and game integrations.

## Decision

This evidence does not justify exposing a partial `DiscordNative` object in production Track B. The earlier partial window/hardware experiment already produced an incomplete page. Matching the group names without implementing the corresponding behavior would make the shell appear desktop-capable while leaving the frontend on an unsupported path.

The normal shell therefore remains on its known-good WebView2 path with the audited desktop user-agent identity but no `DiscordNative` root. Native capability groups must be added only as complete, narrow, behavior-tested paths with a real Windows owner and a rollback switch.

The next viable parity gate is behavior-level evidence from a fully initialized authenticated route. Static group names and IPC event names are inventory evidence only; they do not prove that a particular method is called by the tested Discord workload.

