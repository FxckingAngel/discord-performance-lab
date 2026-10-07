# Track B authenticated diagnostic bridge-activation fix

Date: 2026-10-07  
The source change is committed with this report.

## Finding

The authenticated diagnostic mode previously enabled the incomplete window and hardware bridges. A tab-targeted CDP screenshot showed a completely white Discord page, with `/app`, an empty `#app-mount`, and only 1,034 DOM nodes. This was the same failure mode documented for partial `DiscordNative` exposure.

The authenticated no-bridge mode, using the same profile, rendered the Friends page and passed the readiness predicate. The failure was therefore caused by exposing an incomplete native contract, not by WebView2 failing to load Discord.

## Change

Authenticated modes no longer enable the partial window or hardware bridge. Those bridges remain limited to their isolated diagnostic probes. The normal shell and authenticated diagnostics continue to expose no incomplete `DiscordNative` root.

## Verification

After rebuilding Release, `--diagnostic-authenticated` produced:

- route class: `discord-channels`
- document ready: true
- `#app-mount`: present with 6 children
- DOM nodes: 4,555
- application readiness: true

The normal Track B shell was then restored and remained responsive. Official Discord was not modified.
