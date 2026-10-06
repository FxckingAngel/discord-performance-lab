# Track B blank runtime versus Discord-loaded delta

Date: 2026-10-06

## Scope

Both captures used the same unverified diagnostic runner, with a 60-second settle period followed by a 30-second process/CDP capture. The blank run used `--diagnostic-blank`; the Discord-loaded comparison uses the settled no-bridge diagnostic capture. Neither route or workload was independently verified, so this is an attribution comparison and not an acceptance benchmark.

Sources:

- Blank: `artifacts/track-b-blank-floor-attribution-20261006/`
- Discord-loaded: `artifacts/track-b-cdp-settled-20261006/`

## Complete-tree comparison

| Metric | Blank WebView2 | Discord-loaded | Delta |
|---|---:|---:|---:|
| Process count | 7 | 8 | +1 |
| Private working set median | 70.02 MiB | 389.25 MiB | +319.23 MiB |
| Total working set median | 368.98 MiB | 833.38 MiB | +464.40 MiB |
| Private bytes median | 142.61 MiB | 580.75 MiB | +438.14 MiB |
| CPU median | 0% | 0.108% | +0.108 percentage points |

## Renderer and page-state comparison

| Metric | Blank WebView2 | Discord-loaded | Delta |
|---|---:|---:|---:|
| Renderer private working set median | 10.27 MiB | 287.00 MiB | +276.73 MiB |
| Renderer private bytes median | 18.31 MiB | 351.13 MiB | +332.82 MiB |
| V8 used heap | 0.50 MiB | 106.15 MiB | +105.65 MiB |
| V8 total heap | 1.00 MiB | 112.86 MiB | +111.86 MiB |
| DOM documents | 2 | 15 | +13 |
| DOM nodes | 8 | 6,249 | +6,241 |
| JavaScript listeners | 0 | 2,421 | +2,421 |
| Image elements | 0 | 157 | +157 |
| Video elements | 0 | 3 | +3 |
| Canvas elements | 0 | 4 | +4 |

## Role deltas

The settled Discord-loaded run's private-working-set medians minus the blank run's medians were approximately:

- Renderer: +276.73 MiB
- GPU: +28.41 MiB
- Browser: +9.49 MiB
- Network service: +2.78 MiB
- Storage service: +0.25 MiB
- Native shell: -0.34 MiB
- Crashpad: -0.45 MiB

The loaded Discord process tree also contained an audio service not present in the blank seven-process floor.

## Interpretation

The WebView2 runtime floor is small in private working-set terms in this capture. The large delta is created by loading Discord's frontend and state, not by the blank shell alone. V8 accounts for roughly 106 MiB of the renderer delta, leaving approximately 171 MiB of renderer private-working-set delta outside live V8 used heap. That residual is the current non-V8 target and must be decomposed into Blink, native Chromium, decoded resources, compositor/raster, and other writable pages.

The result does not justify an architecture decision yet. Feature-specific static, media, voice, video, and screen-share transitions still need controlled captures with the same process-page classification.
