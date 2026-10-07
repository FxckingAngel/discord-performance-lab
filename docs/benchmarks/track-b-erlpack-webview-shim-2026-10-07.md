# Isolated WebView2 `discord_erlpack` shim

Date: 2026-10-07  
Mode: diagnostic-only `--diagnostic-erlpack-bridge`, loopback CDP port 9238

The browser bundle from the evaluated MIT-licensed `wetf` package was vendored with its license. The diagnostic shell exposes only a local `DiscordNative.nativeModules.requireModule` shim. It accepts exactly `discord_erlpack` and returns only `pack` and `unpack`; every other module name throws.

The shim uses the configuration established against the official module:

```js
useLegacyAtoms: true
encoding: { key: "binary", string: "binary", array: "list" }
```

## WebView2 result

For `{hello: "world", number: 42, nested: [true, null, "x"]}`:

- returned packed type: `Uint8Array`
- packed length: 73 bytes
- packed bytes matched the official PTB module exactly
- browser-side `unpack` round trip: passed

The official and shim tests used only synthetic data. No Discord payloads or account state were loaded. This does not yet prove that the frontend accepts the shim during real Discord startup, nor does it cover large integers, compression, malformed inputs, or every Erlang term type.

The shim remains diagnostic-only. The normal shell still exposes no `DiscordNative` object.
