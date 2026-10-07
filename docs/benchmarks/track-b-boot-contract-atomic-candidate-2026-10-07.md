# Track B atomic boot-contract candidate

Date: 2026-10-07

Diagnostic mode: `--diagnostic-boot-contract-complete`  
Probe: `tools/Test-TrackBBootContractActivation.mjs 9239`

The candidate was tested after narrowing `DiscordNative` to the observed boot root members, adding three measured `processUtils` calls, adding a diagnostic-only IPC recorder, and removing placeholder native-module objects.

## Sanitized result

| Check | Result |
| --- | --- |
| Candidate marker | `diagnostic-only`, `atomic-candidate` |
| Root shape | expected metadata and seven boot families present |
| Requested native modules | `discord_erlpack`, `discord_voice`, `discord_utils` |
| IPC observation | `ipc.send` with one string-shaped argument; static matching identified `DISCORD_APP_ASYNC_INDEX_TSX_LOADED` |
| Unsupported-module error observed | yes (`discord_voice`, `discord_utils`, and `discord_zstd`) |
| Missing non-module calls | none at the root-shape boundary |
| `setMemoryInformation` call count | 0; property inspection only |
| `#app-mount` child count | 0 |
| Frontend initialized | no |
| Atomic activation passed | no |

The diagnostic candidate records IPC method names, argument shapes, and a local-only fingerprint of the single string argument without retaining its value or dispatching anything. The fingerprint matched the static preload event `DISCORD_APP_ASYNC_INDEX_TSX_LOADED`, an application-load notification. The frontend remains uninitialized because the recorder does not implement real native behavior and `discord_voice`, `discord_utils`, and `discord_zstd` are still unsupported. The three read-only process measurements execute without a contract error. No generic production IPC bridge is authorized.

The clean official Discord instance was not modified. Normal Track B remains on the no-`DiscordNative` path.
