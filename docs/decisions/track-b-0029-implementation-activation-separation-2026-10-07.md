# Track B decision 0029: separate capability implementation from activation

Track B may implement native desktop capability groups independently, but Discord's frontend must not receive an incomplete `DiscordNative` root. The earlier partial bridge produced an empty application mount, so an isolated method test is not evidence that the Discord-facing contract is safe to activate.

## Implementation boundary

An isolated harness may expose one complete group while it is being tested. The harness must verify the source-backed method names, argument and return shapes, synchronous or asynchronous behavior, event delivery, failure behavior, native owner, origin restriction, and resource cost. It must not be treated as a Discord feature or performance result.

## Boot-contract discovery

The pristine official Discord client remains read-only ground truth. Track B may observe sanitized startup metadata from it, including group and method names, call order, argument shapes, return shapes, and success or failure. Diagnostics must exclude account data, messages, tokens, IDs, private URLs, clipboard contents, and file contents.

## Activation boundary

The Discord-facing contract is activated only as one coherent set after every startup dependency in that set has a genuine native implementation. The activation gate rejects unsupported native modules, placeholder methods, unresolved contract errors, missing groups, unexpected groups, and an empty or incomplete `#app-mount`. A diagnostic activation is only considered frontend-initialized when the document is complete, the mount has children, the DOM has at least 100 elements, and the mount has a non-zero client rectangle. These checks are readiness guards, not proof that the contract is functionally complete.

Until that gate passes in an authenticated diagnostic build, the normal shell remains on its known-good desktop identity with no `DiscordNative` root. A passing isolated capability test never authorizes partial production exposure.

## Current state

The current atomic candidate remains diagnostic-only and rejected. It still records unsupported voice and utility module requests and placeholder IPC/process utility paths, and it does not produce a populated Discord application mount. The normal shell and the untouched official reference remain unchanged.
