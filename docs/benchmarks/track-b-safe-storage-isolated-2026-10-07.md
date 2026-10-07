# Track B isolated safe-storage capability

Date: 2026-10-07  
Mode: diagnostic-only `--diagnostic-safe-storage` on loopback CDP port 9237

## Implementation

The probe exposes a narrowly scoped COM-visible WebView2 host object and maps it to the Discord-style methods `isEncryptionAvailable`, `encryptString`, and `decryptString`. The native implementation uses Windows DPAPI `CryptProtectData` and `CryptUnprotectData` with the non-interactive `CRYPTPROTECT_UI_FORBIDDEN` flag. It uses the current Windows user scope and does not use the machine-wide flag.

WebView2's synchronous host-object proxy is used because the vanilla preload contract calls these methods through synchronous IPC. The probe page calls only a synthetic test string; it does not read or write account data, cookies, tokens, or the user's clipboard.

## Result

| Check | Result |
| --- | --- |
| Windows protection available | `true` |
| Encrypted return type | string |
| Encrypted synthetic value length | 328 characters |
| Decrypt round trip | passed |
| Production Discord frontend enabled | no |

This proves a genuine host-backed storage operation and the lower-case wrapper shape. It does not prove that Discord's encrypted-value encoding matches Electron's, so it remains an isolated capability test. The production shell still exposes no `DiscordNative` root.

The WebView2 host-object design follows Microsoft's documented `AddHostObjectToScript` and synchronous host-object proxy behavior. Windows DPAPI's user/machine scope and non-interactive protection behavior follow the `CryptProtectData` documentation.
