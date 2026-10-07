# Track B boot-contract capability tests

Date: 2026-10-07

These tests exercise isolated Track B implementations. They do not modify the clean official Discord reference and do not expose a desktop-native contract in the normal shell.

## Safe storage

Diagnostic mode: `--diagnostic-safe-storage` on loopback port 9237  
Probe: `tools/Test-TrackBSafeStorageBridge.mjs 9237`

| Check | Result |
| --- | --- |
| Encryption availability | `true` |
| Encrypted return shape | string |
| Decrypted value equals input | pass |
| Account, token, and plaintext data recorded | no |
| Production `DiscordNative` exposure | no |

The probe used a fixed non-sensitive test string and retained only the boolean round-trip result and encrypted-string length in its output.

## `discord_erlpack`

Diagnostic mode: `--diagnostic-erlpack-bridge` on loopback port 9238  
Probe: `tools/Test-TrackBErlpackBridge.mjs 9238`

| Check | Result |
| --- | --- |
| Exported methods | `pack`, `unpack` |
| Packed return shape | `Uint8Array` |
| Fixed test object round trip | pass |
| Private Discord data recorded | no |
| Production `DiscordNative` exposure | no |

The test uses a fixed local object and records only aggregate shape, byte count, a deterministic hex representation of that test payload, and the round-trip boolean.

## Read-only process measurements

The atomic candidate now exposes only the three methods observed during startup:

| Method | Native source | Result |
| --- | --- | --- |
| `getCPUCoreCount` | `Environment.ProcessorCount` | executes without a contract error |
| `getCurrentCPUUsagePercent` | current shell process CPU time divided by elapsed time and core count | executes without a contract error |
| `getProcessUptime` | monotonic shell uptime stopwatch | executes without a contract error |

`setMemoryInformation` remains unimplemented because its input and ownership semantics are not yet established. No memory purge or process-control operation was exposed.

## Activation decision

These results prove two isolated behaviors, not the complete Discord desktop contract. `safeStorage` remains an independently tested implementation and is not exposed to the normal Discord frontend. The `nativeModules` family remains unready for atomic activation because the official client requests additional native modules whose behavior has not been implemented and tested. The candidate now rejects every module except the verified `discord_erlpack` shim; it no longer returns placeholder objects for arbitrary module names. Capability tests authorize implementation work only. Discord activation remains atomic and is rejected until the complete boot contract is implemented, tested, and able to initialize `#app-mount`. The six-family diagnostic candidate remains diagnostic-only, and normal Track B continues to omit `DiscordNative`.
