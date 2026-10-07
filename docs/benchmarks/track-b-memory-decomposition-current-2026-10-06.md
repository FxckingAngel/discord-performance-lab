# Track B authenticated memory decomposition

Date: 2026-10-06

The current measurement path uses an authenticated no-bridge diagnostic profile so Discord's frontend renders normally without the incomplete desktop bridge. Parent-child relationships are guarded by process creation time to avoid counting unrelated processes after PID reuse. Raw per-PID captures remain local in the ignored benchmark area.

## Per-role resident and private accounting

The table below is from the labeled 60-second per-PID capture after startup. It preserves the individual PIDs in the raw input; role totals are shown only after each PID was recorded.

| Role | Working set median | Private bytes median | Why it exists | Can it be released while idle? |
| --- | ---: | ---: | --- | --- |
| Native Track B host | 57.16 MiB | 11.99 MiB | WinForms window, WebView2 controller, titlebar, and tray | Only by closing or recreating the shell; no safe idle release identified |
| WebView2 browser | 132.37 MiB | 45.53 MiB | Browser process, profile, compositor coordination, and browser services | Required for the loaded page and profile; internal runtime decision needed |
| Renderer | 391.95 MiB | 328.66 MiB | Discord frontend, Blink, V8, renderer-native allocations, and page resources | Main target; requires frontend/runtime attribution before changing behavior |
| GPU process | 85.11 MiB | 66.51 MiB | Hardware-accelerated compositor and graphics resources | Required for normal acceleration; no safe release strategy identified |
| Network service | 50.44 MiB | 15.69 MiB | Discord API/gateway and web resource networking | Required for messaging, presence, notifications, and media resources |
| Audio service | 28.19 MiB | 8.10 MiB | Chromium audio/media service used by voice and media features | Must remain for normal voice/media support |
| Storage service | 23.78 MiB | 7.66 MiB | Cookies, local storage, IndexedDB, and profile persistence | Required for login/session and Discord state |
| Crashpad | 16.45 MiB | 3.06 MiB | Runtime crash handling | Small; removing it would reduce diagnostics rather than solve the target |

The 60-second capture's role totals are not a substitute for a longer settled acceptance run. The prior 120-second full-tree capture measured 448.83 MiB median private working set and 613.48 MiB median private bytes across eight processes. The short run is useful for category ownership, while the longer run remains the better resource baseline.

## Page and allocation categories

| Category | Current evidence | Status |
| --- | --- | --- |
| V8 heap | Separate authenticated CDP capture measured 118.6 MiB used and 206.3 MiB capacity; the 300-second performance window showed low task/layout activity | Partially attributed; not synchronized to the labeled process sample |
| Blink/DOM/layout | 6,312 to 6,530 DOM nodes, 13 documents/frames in the recent CDP windows; layout and style time remained low | Counts measured, memory not independently exposed by the available interface |
| Images/GIF/media cache | No separate cache-byte counter was collected in this run | Unknown; requires a media-heavy versus static controlled pair |
| GPU/shared graphics | Derived shareable working set was about 426 MiB in the longer tree capture; this is total working set minus private working set, not a native shared-page counter | Partially attributed; do not treat derived shareable bytes as unique memory |
| WebRTC/audio/video allocations | Audio service is present; no active call/media allocation split was collected in this static-channel run | Unknown until voice, video, and screen-share scenarios are captured separately |
| Other Chromium native allocations | Renderer private bytes exceed measured V8 heap by more than 200 MiB in the comparable runs | Dominant residual; requires native memory-infra or scenario isolation |

## Optimization ranking

1. Renderer private resident allocation. It is the largest measured unique-resident owner and exceeds the 250 MiB total target by itself in the current loaded state.
2. GPU/compositor resident allocation. It is materially smaller than the renderer in resident working set, but hardware acceleration must remain enabled.
3. WebView2 browser and renderer shared/native mappings. These account for much of the difference between total working set and private working set and need better native attribution before a change.
4. Network, audio, storage, crashpad, and the native host. These are individually small and required for the requested functionality; removing them would not close the memory gap.

The current evidence does not justify a renderer change yet. It shows where the memory resides, but not which allocation can be released without breaking Discord behavior. The next measurement is a static-channel versus media-heavy pair with the same account and window, retaining per-PID records and CDP aggregate diagnostics.

## Inputs

- `benchmarks/raw/track-b-memory-decomposition-pid-120s-20261006.json`
- `benchmarks/raw/track-b-memory-decomposition-pid-120s-summary-20261006.json`
- `benchmarks/raw/track-b-memory-decomposition-tree-120s-summary-20261006.json`
- `benchmarks/raw/track-b-memory-decomposition-cdp-300s-20261006.json`
- `benchmarks/raw/track-b-current-no-bridges-memory-20261006.json`
