# Track B unauthenticated Discord frontend CDP attribution

This diagnostic used the separate `--diagnostic-discord` profile and loopback CDP port 9224. It did not access credentials, cookies, tokens, account identifiers, message text, URLs, heap objects, or raw heap profiles. The process-tree measurement and CDP probe ran for the same ten-second window.

## Process and browser aggregates

| Metric | Value |
| --- | ---: |
| Complete-tree private working set median | 362.69 MiB |
| Renderer private working set median | 252.18 MiB |
| V8 used heap | 24.07 MiB |
| V8 total heap | 29.50 MiB |
| DOM nodes | 1,037 |
| Frames | 2 |
| Image elements | 0 |
| Animated-image hints | 0 |
| Video elements | 0 |
| Canvas elements | 0 |
| Native sampling during window | 32.22 MiB |
| All-time native sampled total | 60.60 MiB |
| JavaScript allocation sampling | 24.08 MiB |

The available native sampling categories were approximately 32.22 MiB of `chromium-native` and 0.001 MiB of `gpu-graphics` during the ten-second window. The all-time profile exposed approximately 30.61 MiB of `chromium-native` and 30.00 MiB of V8-related sampled data. These values are sampling outputs from CDP and are not additive with private working set.

## Interpretation

The renderer retained approximately 252.18 MiB private working set while measured V8 used heap was only 24.07 MiB. This leaves approximately 228 MiB outside measured live V8 heap in this state. The absence of media elements makes image/GIF/video retention an unlikely explanation for this particular sample, but CDP sampling does not identify the remaining bytes as Blink, Chromium native, mapped pages, or GPU resources.

The native CDP values are sampled allocation signals and must not be added to private working set or treated as a complete native census. The next attribution step remains lifecycle and static-versus-media route comparison with the per-PID region groups preserved.

Raw artifacts remain local under `artifacts/track-b-discord-frontend-cdp-20261007/`.
