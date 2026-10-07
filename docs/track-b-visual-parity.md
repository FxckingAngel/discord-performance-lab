# Track B visual parity requirement

Date: 2026-10-06

Visual parity is a separate Track B acceptance gate alongside performance and functionality. The target is that a normal user can switch between official Discord and Track B without feeling that the Discord application area changed from desktop Discord to a generic browser page.

## Boundary

Discord's own frontend remains responsible for rendering servers, channels, DMs, messages, settings, calls, media, and other Discord UI. Track B must not manually recreate those surfaces or inject rewritten Discord UI code to force screenshots to match.

The native shell may implement desktop-only behavior such as the titlebar, window controls, drag region, navigation controls, window state, tray integration, and system integration when those are needed. Any native capability must be narrowly scoped, documented, reversible, and must not spoof authentication, authorization, entitlements, API behavior, or security state.

## Controlled A/B comparison

Capture official Discord and Track B with:

- the same Discord account and exact DM, channel, or call state;
- the same window dimensions and display scaling;
- the same 1920x1080, 60 Hz display;
- the same frontend route and settled state;
- the same media, voice, video, and screen-share conditions.

The first comparison set covers Friends, a server channel, a DM, Settings, a voice-connected DM, a video call, screen sharing, and a media-heavy channel. Preserve the original screenshots locally and keep them out of public commits when they contain account or message data.

## Difference investigation

For every visible difference, classify whether it is caused by:

- web versus desktop environment detection;
- user-agent or runtime reporting;
- an Electron-specific frontend capability;
- viewport, display scaling, or titlebar/client-area calculations;
- native window chrome or safe-area offsets;
- a desktop-only feature flag;
- a missing preload or native capability;
- CSS or media-query behavior;
- a platform capability reported to the frontend.

Use read-only observation and small, reversible shell capabilities to identify the cause. Do not spoof security state or change Discord's network protocol. If a desktop capability is required, document the expected behavior, the safe WebView2 equivalent, resource cost, and functional test before implementing it.

## Regression workflow

`tools/Capture-DiscordCdpScreenshot.mjs` captures a local PNG from a controlled loopback CDP diagnostic endpoint and records only viewport metadata to stdout. Example:

```text
node tools/Capture-DiscordCdpScreenshot.mjs 9222 benchmarks/private/official-friends.png
node tools/Capture-DiscordCdpScreenshot.mjs 9224 benchmarks/private/track-b-friends.png
```

The screenshot files stay private because they may contain account names, messages, or other Discord content. The two captures are valid for comparison only after the same account, route, call state, window dimensions, display scaling, and settled workload have been established. The next workflow step is an aligned pixel/difference report over these local pairs. Visual regressions are tracked separately from performance regressions. A lower memory number does not offset a visible or functional desktop regression.

The authenticated-profile probe on 2026-10-06 produced a blank white private capture despite loading the `/app` route, so no visual-parity conclusion was drawn. A user-visible, same-state capture remains required before comparing official Discord with Track B.

## Manual checkpoint

When the native-window connector cannot inspect the desktop window, run `tools/Invoke-TrackBVisualCheckpoint.ps1` after placing the official and Track B screenshots on the local machine. Confirm each condition interactively. The script records only the confirmations and sanitized pixel-error metrics. It does not copy, publish, or embed either screenshot. Missing confirmations leave the result as `WAITING_FOR_MANUAL_CHECKPOINT`.

`tools/Compare-DiscordScreenshots.py` compares two same-sized PNGs locally and reports differing-pixel percentage, mean absolute channel error, p95 pixel error, and maximum pixel error. It writes no image content and has no network or Discord integration. A metric of zero is only meaningful for a controlled same-state pair; it is not a substitute for functional review.

No Track B release or public repository decision is made until the authenticated A/B comparison, required functional checks, performance gates, and visual parity review are complete.

## Official control rule

The clean vanilla Discord instance is a read-only reference client. Do not patch its files, inject scripts, alter its preload, add plugins, change runtime flags, force DPI or zoom, modify renderer behavior, or enable or disable features for a comparison. Read-only observation of its non-sensitive geometry, process tree, resource counters, capability shapes, and visual output is allowed.

Any session that requires a diagnostic launch option or instrumentation that could change behavior is labeled an official diagnostic session and is not the canonical official baseline. Track B must adapt to the untouched official behavior; the control must not be changed to resemble Track B. The desktop parity oracle must only read both endpoints and native window facts. It must not call window-management APIs against the official PID.

The oracle records the actual client-area origin from `ClientToScreen`, the window DPI-awareness context, and monitor/work-area geometry. Its page probe reports `visualViewport.scale` separately and leaves browser `zoomFactor` unknown unless a host-side WebView API supplies it. This avoids treating viewport scale as browser zoom or deriving the titlebar offset from total window and client heights.

## Media-quality gate

Images, avatars, GIFs, stickers, video, and embeds must render at quality comparable to pristine Official Discord. Track B must not lower source resolution, decoded resolution, raster quality, texture quality, or visible animation to satisfy the memory target. A controlled no-media benchmark is diagnostic only and cannot establish production parity. Before changing rendering settings, use the sanitized media-quality probe to distinguish a lower-resolution source asset from a correct asset presented at the wrong DPI, zoom, viewport, or raster scale.
