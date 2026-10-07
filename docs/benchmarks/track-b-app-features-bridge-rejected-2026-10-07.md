# Track B app/features bridge experiment

The diagnostic-only bridge was extended with three values that had real local backing: Discord app identity (`getVersion`, release channel, architecture, language direction), an explicit unsupported-feature response, and `isRenderer`. The existing real window and display-count bridges remained enabled.

The experiment did not move the authenticated diagnostic page beyond the incomplete state:

- 1,036 DOM nodes
- 2 frames
- no image, video, or canvas elements
- approximately 37.67 MiB V8 used heap
- no useful console summary from the sanitized CDP capture

This is not a desktop-parity implementation and not a performance result. The app/features additions are rejected and removed from the shell source. The result supports the current design rule: Discord's frontend needs a compatibility-shaped native surface, not a few plausible group names or identity values. The normal shell remains unchanged and continues to expose no partial `DiscordNative` object.

Raw diagnostic output remains local at `artifacts/track-b-app-features-bridge-20261007.json`.
