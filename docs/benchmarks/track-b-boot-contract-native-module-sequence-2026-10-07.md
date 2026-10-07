# Track B boot-contract native-module sequence

Date: 2026-10-07  
Source: read-only local Electron preload and diagnostic-only full-shape WebView2 probe

## Sanitized startup observations

The diagnostic surface used the complete 33-group property shape from the local preload, real process/OS/app metadata, DPAPI-backed storage, and non-functional placeholders for the remaining groups. It recorded these calls before the application root initialized:

| Group | Observed operation | Status |
| --- | --- | --- |
| app | `getVersion`, `getReleaseChannel`, `getBuildNumber`, `getModuleVersions`, `getPreferredSystemLanguages` | Host-backed metadata implemented in the probe |
| safeStorage | `isEncryptionAvailable` | Host-backed DPAPI probe passes synthetic round-trip |
| processUtils | `getCPUCoreCount` | Host-backed processor count implemented in the probe |
| nativeModules | `requireModule` | Requests `discord_voice`, `discord_utils`, and `discord_erlpack` |
| ipc | `send` | Event name/value deliberately not retained; generic IPC is not implemented |

The result still did not populate `#app-mount`. This is not a functional or performance result.

A second diagnostic pass returned traceable proxies for allow-listed `discord_*` modules. It reached additional startup calls without invoking any official binary:

- `discord_voice`: device enumeration, callback registration, audio-subsystem and codec-survey queries, volume/AEC/sidechain setup;
- `discord_utils`: memory usage, permission authorization, and game-candidate setup;
- `discord_zstd`: `createContext`;
- `nativeModules.ensureModule`, `app.getPath`, `window.setDevtoolsCallbacks`, `features.supports`, and `powerMonitor` methods.

The page still did not initialize because these proxy methods have no real owners. This is evidence of contract breadth, not a candidate implementation.

## Native-module boundary

The untouched local PTB installation contains native `discord_voice.node` and `discord_utils.node` modules. The utility package exports process, input, game-integration, crash, and system-service functions. The voice package wraps the native voice engine and exposes connection, audio, video, and secure-frame behavior. These modules depend on the Electron/Node native-module environment and cannot be copied into WebView2 or treated as browser JavaScript.

Track B must not load those binaries, bypass their ABI boundary, or expose placeholder objects as production capability. The browser `discord_erlpack` replacement remains valid only for the codec surface already matched against the official module.

## Decision

The minimum coherent desktop contract is larger than metadata, storage, and Erlang packing. The next architecture decision is whether to provide genuine native equivalents for the voice and utility contracts, or to keep Discord on a supported browser/WebRTC path while preserving full voice/video behavior. Either route requires an end-to-end authenticated test before activation. The normal shell remains free of `DiscordNative`.
