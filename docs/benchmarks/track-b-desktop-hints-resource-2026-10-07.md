# Track B desktop-hints resource check

Date: 2026-10-07  
Mode: `--diagnostic-desktop-hints`  
Profile: isolated `DesktopHintsProbeUserData`  
Route: unauthenticated diagnostic state  
Display: 1920x1080 at 60 Hz

## Result

The mode started with one transient startup sample at nine processes, then settled at eight processes. No Discord-native bridge was exposed.

| Metric | First sample | Settled range | Last sample |
|---|---:|---:|---:|
| Complete-tree private working set | 327.84 MiB | 260.25–308.37 MiB | 260.25 MiB |
| Renderer private working set | 210.05 MiB | 161.78–210.27 MiB | 161.78 MiB |
| CPU | 0.00% | 0.02–0.47% | 0.02% |
| Process count | 9 | 8 | 8 |

The resource capture used seven samples over approximately 37 seconds. The decreasing resident memory is consistent with the lifecycle behavior already observed in the normal shell. It does not isolate a client-hints cost from ordinary WebView2/Discord settling behavior.

## Environment result

The corrected sanitized probe reported the same environment values as the isolated vanilla reference for the relevant fields:

- `navigator.platform`: `Win32`
- `navigator.userAgentData.platform`: `Windows`
- brands: `Not/A)Brand`, `Chromium`
- `DiscordNative`: absent

## Decision

The client-hints diagnostic has no evidence of a large extra process or CPU cost, but it is not a production change and does not establish visual or functional parity. Keep it isolated until the same-account route comparison covers initialization, screenshots, and normal Discord workloads.
