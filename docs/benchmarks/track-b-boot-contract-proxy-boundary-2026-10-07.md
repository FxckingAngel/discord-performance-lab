# Track B boot-contract proxy boundary

Date: 2026-10-07  
Mode: diagnostic-only `--diagnostic-boot-contract`, loopback CDP port 9236  
Raw event log: local `%LOCALAPPDATA%\\KoroneDiscordShell\\Diagnostics\\capability-events-<pid>-<utc>.jsonl`

The diagnostic proxy was run against Track B's authenticated WebView2 profile. It records only sanitized property paths, event types, argument counts, primitive argument shapes, and the allowlisted native-module name. It does not record return values, page text, account data, message data, tokens, cookies, private URLs, clipboard contents, or file contents.

## Observed boundary

Before the proxy stalled the frontend, Discord accessed:

- `DiscordNative.app`
- `DiscordNative.process`
- `DiscordNative.os`
- `DiscordNative.safeStorage.isEncryptionAvailable()`
- `DiscordNative.nativeModules.requireModule('discord_erlpack')`

The proxy deliberately returns undefined-like placeholders for unresolved operations. The page reached `readyState: complete`, but `#app-mount` remained empty. No later access sequence from this run is trustworthy because the placeholder return behavior changes control flow.

## Decision

This run is evidence for the boot boundary, not a capability implementation. It does not justify adding guessed `DiscordNative` groups, generic IPC dispatch, `discord_voice`, or `discord_utils` to the normal shell. The normal shell remains on the no-`DiscordNative` path.

The next desktop-parity work must use either a genuine native implementation with an end-to-end workload test or a separately labeled official diagnostic boundary that preserves return and error behavior. A proxy that returns placeholders cannot establish the complete startup contract.

The normal Track B shell was restored after the diagnostic and was responding. Official Discord was not modified.

Each diagnostic launch now gets its own PID/timestamped JSONL file so separate runs cannot be mistaken for one another. A rebuilt probe produced a new 3,540-byte per-run log and the normal shell was restored afterward.
