# Track B atomic boot-contract experiment

Date: 2026-10-07  
Mode: diagnostic-only `--diagnostic-boot-contract-complete`, loopback CDP port 9239

## Purpose

This experiment activated the currently tested boot families together in one document-created script:

- read-only process and OS metadata;
- shell-backed app version, build, release-channel, and architecture values;
- Windows DPAPI-backed safe storage;
- the browser `discord_erlpack` codec whose synthetic output matched the official module.

The normal shell was not changed. The official Discord client was not touched.

## Result

The page reached `document.readyState = complete` and exposed the five expected groups, but Discord's application did not initialize:

| Check | Result |
| --- | --- |
| `DiscordNative` present | yes |
| `app`, `nativeModules`, `os`, `process`, `safeStorage` present | yes |
| DOM body children | 2 |
| `#app-mount` present | yes |
| `#app-mount` children | 0 |
| `#app-mount` height | 0 px |
| production activation | rejected |

A sanitized CDP startup probe also observed a `ReferenceError` and a host-result error. Their presence is evidence of a contract mismatch, not proof that either individual capability is the cause. No page text, account data, tokens, private URLs, or raw exception payloads were retained.

## Decision

The five-family surface is not yet the minimum coherent vanilla contract. The atomic mode remains useful for reproducing the failure, but it is not a functional Discord client, performance result, or desktop-parity result. The production shell continues to expose no `DiscordNative` root object.

The next investigation must compare the exact official return descriptors and startup dependencies, then add only a complete capability group with a real native owner. It must not add arbitrary stubs to make the page advance.
