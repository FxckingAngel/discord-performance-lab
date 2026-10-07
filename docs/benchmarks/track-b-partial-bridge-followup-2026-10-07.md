# Track B partial bridge follow-up

This diagnostic reused the authenticated Track B profile with the existing window and hardware bridge enabled. It was run after the separate vanilla capability probe identified the much larger official `DiscordNative` surface. The normal shell was not changed.

The page remained a small incomplete state:

| Metric | Result |
| --- | ---: |
| DOM nodes | 1,036 |
| Frames | 2 |
| Image/video/canvas elements | 0 / 0 / 0 |
| V8 used heap | 37.80 MiB |
| V8 total heap | 45.07 MiB |
| Embedder heap | 9.27 MiB |
| Backing storage | 16.70 MiB |

The result is consistent with the earlier white-page/incomplete-frontend observation. It is not evidence that the two native groups are sufficient for desktop parity, and it is not a performance result. The normal shell must continue to expose no partial `DiscordNative` object until a compatibility-shaped surface is implemented and each reported capability has a real native behavior.

Raw CDP output remains local at `artifacts/track-b-partial-bridge-followup-20261007.json`.
