# Read-only `discord_erlpack` inspection

Date: 2026-10-07  
Source: untouched official Discord PTB module directory

The official module was inspected without modifying or launching the official Discord client. Its package wrapper contains only the native `discord_erlpack.node` binary and a one-line CommonJS loader.

The native module exports exactly two functions:

- `pack`
- `unpack`

A synthetic local-process test passed this object through both functions:

`{ hello: "world", number: 42 }`

The result was a 39-byte Buffer from `pack` and the original object from `unpack`. No Discord data, account state, network traffic, or official client process was involved.

## Track B decision

This is a binary serialization dependency, not a general desktop capability. Track B will not load the official Node native binary into WebView2. A future replacement would need to implement the same wire format in a supported, audited browser-side or native component and be tested against sanitized fixtures. Until then, `nativeModules` remains unavailable in production and the desktop contract is not claimed complete.
