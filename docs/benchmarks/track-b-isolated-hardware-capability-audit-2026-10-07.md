# Track B isolated hardware capability audit

Date: 2026-10-07  
Scope: current read-only vanilla preload extraction and the current Track B shell. No official Discord process, file, preload, profile, or launch configuration was changed. No production shell source was changed.

## Decision

The one complete `DiscordNative` group currently suitable for an isolated compatibility harness is:

`DiscordNative.hardware.getDisplayCount`

This is a narrow hardware group, not a claim that Track B has a complete Discord desktop contract. It is selected because the sanitized vanilla probe shows the group contains exactly one method, and Track B already has a genuine native owner for the same conceptual operation. It must remain diagnostic-only until vanilla timing and return semantics are verified.

The normal shell must continue to expose no `DiscordNative` root.

## Evidence from the vanilla extraction

The sanitized environment probe at `artifacts/discord-vanilla-environment-probe-complete-20261007.json` reports:

| Property | Observed value |
| --- | --- |
| `DiscordNative.hardware` | present object |
| own properties | one property: `getDisplayCount` |
| property type | function |

The static module map identifies the group as preload module `6955` and records the direct IPC reference `HARDWARE_GET_DISPLAY_COUNT`. The static contract contains the same group and IPC event. This establishes the group boundary and its native operation name, but it does not establish whether the vanilla function is synchronous or promise-returning, its exact argument shape, or its exact error behavior.

The current vanilla runtime-call probe could not wrap the non-configurable preload descriptors. Its empty call sequence is therefore not evidence that Discord never calls this method.

## Evidence from the current Track B shell

The diagnostic-only shell path is implemented in `track-b/discord-shell/MainForm.cs` and selected by `--diagnostic-hardware-bridge` or `--diagnostic-bridge-pair` in `Program.cs`.

The isolated harness:

- creates a separate WebView2 profile;
- loads a local blank document rather than Discord;
- exposes only `DiscordNative.hardware.getDisplayCount`;
- sends one sanitized request through the WebView2 message channel;
- answers with `Screen.AllScreens.Length`;
- returns no display names, coordinates, handles, account data, or private URLs;
- keeps the production shell and normal Discord page on the no-bridge path.

The current method is promise-backed. The isolated probe returned the actual display count, `2`, and the process remained responsive. The existing three-run resource report recorded a median of 72.86 MiB private working set and 0.020% CPU across seven diagnostic processes, within the measured blank WebView2 floor. That result is diagnostic evidence only and does not prove Discord uses the method or that the bridge is cheaper than an equivalent production implementation.

The bridge-pair probe also confirmed that the hardware group can coexist with the diagnostic window group without replacing either group. That is a shape test, not a Discord boot test.

The expanded isolated probe then called the method three times: twice with no arguments and once with a sanitized diagnostic object. All three calls returned the number `2`; the first call took 11.118 ms and the following calls took 0.841 ms and 0.643 ms. This confirms repeatability and the current hypothesis that extra arguments are ignored by the Track B diagnostic wrapper. It still does not prove that vanilla Discord accepts extra arguments or that the vanilla method has the same timing and promise semantics.

## Why the other candidates are not selected

| Group | Current evidence | Decision |
| --- | --- | --- |
| `clipboard` | Vanilla exposes seven methods. The shell has browser clipboard support, but no audited mapping for text, image, file, mixed-content, cut, copy, paste, permission, or error semantics. | Not ready |
| `fileManager` | Vanilla exposes a large mixed surface containing dialogs, path helpers, downloads, voice-message and model/clip helpers. The shell has no complete contract or cancellation/error mapping. | Not ready |
| `window` | Vanilla exposes 25 members, including media-source IDs, native handles, content protection, throttling, frame rate, PiP, progress, zoom, and callbacks. Track B's five-action diagnostic bridge is only a subset. | Not ready |
| `desktopCapture` | Vanilla exposes one method, but Track B has no genuine Discord-compatible source enumeration and selection implementation behind it. WebView2 display capture alone is insufficient. | Not ready |
| `features` | Vanilla exposes `declareSupported` and `supports`, but declaring a feature without a complete native implementation would create false desktop capability signals. | Not ready |

## Missing semantics for the selected group

Before any activation experiment against Discord, the following must be resolved from a separately labeled vanilla diagnostic session or an equivalent pre-preload boundary:

1. Whether `getDisplayCount` returns synchronously or returns a promise.
2. Whether it accepts arguments, and the accepted argument count and types.
3. The exact successful return type and value rules when displays are added or removed.
4. The exact rejection or exception behavior if display enumeration fails.
5. Whether the call is used during startup, route navigation, voice/video, screen sharing, or settings.
6. Whether Discord expects a display-count update event or only an on-demand query.

Until those items are measured, the current promise-backed method is an isolated Track B hypothesis, not a proven drop-in vanilla replacement.

## Safe isolated-test plan

1. Keep the untouched official client as the canonical control. If runtime observation is required, use a separately labeled diagnostic session and do not use it for the final performance baseline.
2. Extend the local harness to exercise only `hardware.getDisplayCount` with zero arguments, extra arguments, and a repeated call. Record method-name, timing class, sanitized type, success/failure, and value type only. Never record display names, coordinates, handles, account data, URLs, tokens, or page text.
3. In the native harness, compare the returned count with a read-only Windows display enumeration at the same instant. Test normal enumeration, monitor add/remove if safely available, and an enumeration failure path without changing Discord state.
4. Verify the bridge is origin-restricted for Discord HTTPS origins and absent for local/untrusted pages. Keep the isolated profile, loopback endpoint, and rollback switch separate from the normal shell.
5. Run the harness with the root absent, with hardware only, and with the hardware object recreated from scratch. Compare readiness, process count, private working set, private bytes, CPU, and responsiveness. Do not use the blank harness as a Discord performance result.
6. Only after the exact vanilla semantics are known, expose this single group in a disposable diagnostic Discord build. Verify application readiness, populated `#app-mount`, a static route, messaging, media quality, and the absence of the prior white-page failure. Remove the entire root on any failure.

## Activation boundary

This report authorizes no production change. A successful isolated hardware test would demonstrate one safely owned capability, but it would not justify exposing a partial `DiscordNative` root to the real Discord frontend. Activation still requires a coherent boot contract and evidence for every group that Discord actually consumes on the tested route.

## Evidence files

- `artifacts/discord-vanilla-environment-probe-complete-20261007.json`
- `docs/benchmarks/track-b-preload-contract-2026-10-07.md`
- `docs/benchmarks/track-b-vanilla-preload-module-map-2026-10-07.md`
- `docs/benchmarks/track-b-vanilla-preload-static-order-2026-10-07.md`
- `docs/benchmarks/track-b-hardware-bridge-2026-10-06.md`
- `docs/benchmarks/track-b-desktop-compatibility-bridge-pair-2026-10-06.md`
- `track-b/discord-shell/MainForm.cs`
- `track-b/discord-shell/Program.cs`
