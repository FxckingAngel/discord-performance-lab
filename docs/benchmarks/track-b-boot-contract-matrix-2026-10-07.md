# Track B boot-contract matrix

Date: 2026-10-07  
Sources: read-only PTB `mainScreenPreload.js` extraction and the isolated Track B boot probe

The static extraction identifies the exports below. The boot probe independently observed accesses to all five families before the diagnostic page stopped progressing. Static exports are not treated as proof that every method is needed on every route.

| Family | Vanilla exports | Static IPC dependencies | Boot-probe evidence | Track B status |
| --- | --- | --- | --- | --- |
| `process` | `env`, `arch`, `platform`, `pid` | none in the preload module | `platform` and serialization access | The vanilla values are direct properties, not calls. Not implemented in a bridge. Host values are available, but exposing environment variables or a PID needs a data-minimization decision. |
| `os` | `buildRevision`, `release`, `arch`, `appArch` | none in the preload module | `release`, `arch`, `appArch` and serialization access | The vanilla values are direct properties. `arch` and `appArch` are derived from the host architecture, and `release` comes from the OS. Not implemented in a bridge. |
| `app` | `getVersion`, `getBuildNumber`, `getReleaseChannel`, `getAppArch`, `getDefaultDoubleClickAction`, `getModuleVersions`, `getOpenOnStart`, `getPreferredSystemLanguages`, `getSystemUIDirection`, `pauseFrameEvictor`, `unpauseFrameEvictor`, `registerUserInteractionHandler`, `relaunch`, `setBadgeCount`, plus `dock` | release channel, host version, build number, architecture, module versions, startup setting, language/UI direction, frame-evictor, relaunch, badge/dock | `getVersion`, `getBuildNumber`, `getReleaseChannel` | The observed version/build/channel methods return cached values synchronously; module versions and most other methods use async IPC. Not implemented. Read-only metadata and mutating window/startup/badge behavior must be separated. |
| `safeStorage` | `isEncryptionAvailable`, `decryptString`, `encryptString` | none in the preload module | `isEncryptionAvailable` repeated | Isolated implementation passes a Windows-protected encrypt/decrypt round trip with the expected synchronous shape. Production activation remains gated on the complete boot contract and exact failure behavior. |
| `nativeModules` | `canBootstrapNewUpdater`, `ensureModule`, `requireModule`, `getModulePath` | none in the preload module | `requireModule('discord_erlpack')`; the name was recorded only after the official allow-list check | An isolated browser-safe `discord_erlpack` round trip passes. Other requested native modules remain unsupported, so the family is not ready for production activation. |

## Activation decision

The six families form the smallest observed boot-critical candidate after the live probe requested three read-only `processUtils` methods. `safeStorage` and `nativeModules` are security-sensitive, and `process.env` plus module paths may expose local information. Capability groups are implemented behind isolated tests; the six-family surface remains a diagnostic candidate and is not activated in the normal shell. Activation is atomic and requires exact behavior for every exposed member, followed by a fully initialized Discord frontend. `tools/Test-TrackBBootContractActivation.mjs` checks the contract marker, root shape, contract errors, and frontend initialization. The production shell continues to omit `DiscordNative` until every exposed method has genuine behavior and the full frontend initializes with it enabled.

The clean official Discord process remains read-only. No files, preload code, flags, profile, or renderer behavior were changed. The isolated capability evidence is recorded in [the capability test report](track-b-boot-contract-capability-tests-2026-10-07.md).
