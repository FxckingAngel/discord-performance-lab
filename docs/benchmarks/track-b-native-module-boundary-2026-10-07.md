# Track B native-module boundary

Date: 2026-10-07  
Mode: diagnostic-only boot-contract probe

The sanitized boot probe recorded the requested module name only after applying the vanilla allow-list check. Discord requested:

`discord_erlpack`

This name also exists as `discord_erlpack.node` in the untouched official PTB installation. It is a native Node module, not a WebView2 JavaScript module. Track B does not load the official binary, inject Node into WebView2, or copy the official module into the shell.

## Decision

`nativeModules.requireModule` remains unimplemented in Track B. Loading the official native binary would couple the shell to Node/Electron ABI details and would cross the desktop compatibility boundary without a tested WebView2 equivalent. Replacing it with an unverified JavaScript or WebAssembly codec would not establish parity.

The next safe investigation is to determine which frontend operation requests `discord_erlpack` and whether Discord has a browser/Web API fallback for that operation. Until that evidence exists, the module name is recorded as a requirement and no production capability is claimed.

The module name was captured under the diagnostic allow-list rule; arbitrary argument values remain excluded from the log. The official client was not modified.
