# Track B isolated power-monitor capability

Date: 2026-10-07

The diagnostic mode `--diagnostic-power-monitor` exposes only a local, read-only `powerMonitor.getSystemIdleTimeMs` probe. It is not loaded by the normal shell and is not part of the Discord-facing boot-contract candidate.

The native implementation uses Windows `GetLastInputInfo` and converts the session's tick count into a non-negative elapsed millisecond value. Microsoft documents this API as session-specific input-idle information, so the result is not treated as a machine-wide or cross-session activity signal.

Probe:

```text
node tools/Test-TrackBPowerMonitor.mjs 9242
```

This is an implementation-phase result only. It does not authorize exposing a partial `DiscordNative` object to normal Discord. Electron's event methods (`on` and `removeAllListeners`) remain unimplemented because no equivalent native event contract has been established yet.

Source: Microsoft Learn, “GetLastInputInfo function” and “LASTINPUTINFO structure,” accessed 2026-10-07.
