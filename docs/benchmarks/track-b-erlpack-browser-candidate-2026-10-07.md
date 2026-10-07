# Browser-safe `discord_erlpack` candidate

Date: 2026-10-07  
Official oracle: untouched PTB `discord_erlpack.node`  
Candidate: `wetf` 0.9.14, evaluated in a separate temporary Node process

The official module and the candidate were compared only with synthetic values. No Discord payloads, account data, URLs, or network traffic were used.

## Candidate configuration

The candidate matched the official encoder with:

```js
new Packer({
  useLegacyAtoms: true,
  encoding: { key: 'binary', string: 'binary', array: 'list' }
})
```

For decoder comparison, the candidate used UTF-8 decoding for binary and string terms and decoded nil as `null`.

## Results

The candidate matched the official packed bytes for these fixtures:

- `null`
- `true` and `false`
- strings
- positive and negative integers
- floats
- objects with boolean/string/null values
- arrays
- nested objects and arrays

The candidate decoder produced the same sanitized values as the official decoder for the same fixtures. The simple object `{hello: "world", number: 42}` matched at 39 bytes.

## Decision

`wetf` is a credible browser-safe compatibility candidate because it is pure JavaScript/TypeScript-oriented and documents browser support. It is not approved for production yet. Remaining tests must cover large integers, binary/typed-array values, Unicode, compression, malformed inputs, tuple/atom behavior, error shapes, and the exact frontend call contract.

The next step is an isolated WebView2 native-module shim test that returns only `pack` and `unpack` for the allow-listed `discord_erlpack` name. The normal Discord shell will remain unchanged until that shim passes broader parity tests and the frontend reaches a complete initialized state.

Sources: [Discord erlpack](https://github.com/discord/erlpack), [wetf](https://github.com/timotejroiko/wetf), [Erlang external term format](https://www.erlang.org/docs/20/apps/erts/erl_ext_dist.html).
