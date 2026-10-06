# Experiment 009: native WebView2 host footprint

Date: 2026-10-06

## Scope

This experiment added a diagnostic-only `--diagnostic-native-host` mode. It hosts a blank WebView2 controller in a minimal `NativeWindow`/`ApplicationContext` instead of the production WinForms `Form`, custom titlebar, tray icon, and native bridges. The normal Track B launch path was not changed.

Microsoft documents `CoreWebView2Environment.CreateCoreWebView2ControllerAsync(IntPtr)` as creating a WebView whose parent is the supplied native window handle. The probe uses that supported controller API: [Microsoft WebView2 API reference](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2environment.createcorewebview2controllerasync).

## Result

The probe ran for 132.3 seconds with eight samples at 15-second intervals.

| Metric | Production blank shell | Native-host probe | Difference |
| --- | ---: | ---: | ---: |
| Summed working set median | 370.03 MiB | 354.23 MiB | -15.80 MiB |
| Private working set median | 67.14 MiB | 72.51 MiB | +5.37 MiB |
| Private bytes median | 146.69 MiB | 143.92 MiB | -2.77 MiB |
| Total CPU | 0.011% | 0.018% | higher in probe |
| Process count | 7 | 7 | unchanged |

The native-shell role was 8.72 MiB private bytes in the probe versus approximately 11.38 MiB in the production authenticated run. The probe therefore demonstrates a small host-layer opportunity, not a renderer solution. It does not preserve the production titlebar, tray, window bridge, display bridge, or authenticated Discord workload and cannot replace the normal shell.

## Decision

Do not replace the production WinForms shell with this probe yet. Its measured private-bytes saving is smaller than the remaining authenticated gap, and its CPU result was worse. Keep the code as a diagnostic architecture candidate while renderer attribution remains the primary target.

The probe is reversible through the diagnostic argument and does not alter the normal shell profile or Discord protocol.

## Authenticated follow-up

The same minimal host was then run against the normal Track B WebView2 profile for 126.8 seconds. It reached an eight-process tree with median private bytes of 582.50 MiB and median renderer private bytes of 353.13 MiB. The capture began at 854.27 MiB private bytes and ended at 541.27 MiB, so it had not reached a stable settled state. It also created an audio service that was not present in the one-renderer production settled capture.

This follow-up is not an acceptance comparison and does not demonstrate a saving on the authenticated workload. It rejects promoting the minimal host based on the current evidence. The production shell remains the only Track B implementation under measurement, and renderer attribution remains the primary optimization path.

Raw samples remain local at `benchmarks/raw/track-b-native-host-probe-20261006.json`, `benchmarks/raw/track-b-native-host-probe-20261006-summary.json`, `benchmarks/raw/track-b-native-host-authenticated-20261006.json`, and its summary file.
