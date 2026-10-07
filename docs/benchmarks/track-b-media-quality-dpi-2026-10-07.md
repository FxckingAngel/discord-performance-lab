# Track B media-quality and DPI investigation

Date: 2026-10-07

Status: diagnostic evidence. Media-quality parity is not yet accepted.

## Paired observation

The isolated vanilla PTB reference and Track B were both measured on the Friends route with the sanitized CDP probes. Raw page content, URLs, account data, cookies, tokens, and image pixels were not written.

| Measurement | Official vanilla | Track B before DPI correction |
| --- | ---: | ---: |
| Viewport | 1284 x 728 | 1280 x 768 |
| Device pixel ratio | 1.5 | 1.0 |
| Image count | 150 | 132 |
| Median intrinsic image size | 48 x 48 | 32 x 32 |
| Median displayed image size | 24 x 24 | 32 x 32 |
| Maximum intrinsic image size | 640 x 640 | 640 x 640 |
| Images with coarse quality parameter | 22 | 22 |

This was not a valid visual-parity pass because the page states and viewport geometry were not identical. It does establish that the lower-quality appearance cannot yet be attributed only to a smaller source asset. The same maximum intrinsic size and quality-parameter count were observed, while the median source and displayed dimensions differed.

## Native cause found

The Track B shell was DPI-unaware. The native Track B window reported 96 DPI, while the isolated official PTB window reported 144 DPI on the same display. Track B's WebView2 renderer reported `--device-scale-factor=1` and page DPR 1.0. The official renderer also exposed the Chromium scale flag as 1, but its Electron window context produced page DPR 1.5.

The shell now opts into WinForms `PerMonitorV2` through `ApplicationHighDpiMode`. Microsoft documents this as the mode that enables child-window DPI notifications and improved control scaling. The WebView2 process command line then reported `--embedded-browser-webview-dpi-awareness=2`, and the page reported DPR 1.5.

## Remaining geometry issue

After the DPI correction, Track B reported DPR 1.5 but a CSS viewport of 854 x 512 from the existing 1280 x 800 shell dimensions. That does not match the official 1284 x 728 viewport. The correction therefore remains a source-level fix under test, not a completed parity fix. The next change must establish matched logical content geometry and verify intrinsic and displayed media dimensions again. It must not use a global quality reduction or arbitrary zoom to conceal the mismatch.

## Acceptance rule

Images, avatars, GIFs, stickers, video, and embeds must render at quality comparable to pristine Official Discord. A memory reduction is rejected if it lowers source resolution, decode quality, raster or texture quality, device scale, or visible animation. The sanitized probe is `tools/Probe-DiscordMediaQuality.mjs`; it records aggregate dimensions, viewport scale, and coarse source-parameter buckets without retaining private URLs or image data.

Use `tools/Compare-DiscordMediaQuality.mjs <official-report.json> <track-b-report.json> <comparison.json>` to derive the acceptance fields from two sanitized probe outputs. It checks source dimensions, displayed dimensions, viewport scale, quality-hint parity, and CDP GPU feature-status buckets. The resulting `comparison` object can be passed to `tools/Invoke-TrackBVisualCheckpoint.ps1 -MediaQualityReport`; it does not accept a manually asserted quality flag as a substitute for the probe pair.

Sources: [Microsoft WinForms HighDpiMode](https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.highdpimode), [Microsoft application manifests and DPI awareness](https://learn.microsoft.com/en-us/windows/win32/sbscs/application-manifests), and [Microsoft WebView2 browser flags](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/webview-features-flags).
