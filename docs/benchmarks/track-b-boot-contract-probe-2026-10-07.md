# Track B isolated boot-contract probe

Date: 2026-10-07  
Mode: diagnostic-only `--diagnostic-boot-contract`  
Endpoint: loopback CDP port 9236

## Purpose

This probe installed a local recording proxy for `DiscordNative` in the Track B WebView before Discord navigation. The proxy recorded only property paths, event type, argument count, and primitive argument shapes. It never recorded argument values, page text, URLs, account data, tokens, cookies, IDs, clipboard contents, or file contents. The raw JSONL log remains outside the repository under the local diagnostics directory.

The proxy returned no real native values. That intentionally makes the page unsuitable for normal use and keeps this experiment separate from the production shell.

## Observed access before the diagnostic page stopped progressing

The first access families were:

| Family | Observed evidence | Interpretation |
| --- | --- | --- |
| `process` | `platform`, including repeated serialization access | Boot metadata; native value still needs an audited equivalent. |
| `os` | `release`, `arch`, `appArch`, including repeated serialization access | Boot metadata; values must come from the host, not a spoofed Electron object. |
| `app` | `getVersion`, `getBuildNumber`, `getReleaseChannel` | Boot metadata; the exact vanilla return values and sync/async behavior still need a separate read-only reference check. |
| `safeStorage` | `isEncryptionAvailable` was called repeatedly | Security-sensitive capability. It must use a genuine Windows-backed implementation before it can be exposed. |
| `nativeModules` | `requireModule` was called with one string-shaped argument | No implementation is approved. The module name and safe supported surface require further auditing. |

The captured log contained 32 property-read events and 16 calls. The most frequent paths were `safeStorage.isEncryptionAvailable` (6), the five metadata methods/serialization paths (2–4 each), and `nativeModules.requireModule` (2). Counts are from this one diagnostic launch and are not a production workload frequency measurement.

## Decision

This is the first behavior-level evidence for a minimum boot-critical family, but it is not sufficient to expose `DiscordNative`. The proxy changes frontend behavior and cannot provide trustworthy return values, so it cannot establish visual parity or a complete vanilla startup sequence.

The next implementation boundary is an isolated contract harness for the five observed families. It must test real host-backed results and exact sync/async/error behavior, with special review for `safeStorage` and `nativeModules`. No partial root is enabled in the normal shell. The official Discord client remains an untouched read-only reference.
