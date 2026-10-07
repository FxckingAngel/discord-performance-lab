# Track B low/high authenticated-state control matrix

Date: 2026-10-07

The low and high observations were not a one-variable-controlled pair. The measured shell executable was the same build at commit `afab73adb0389ec9d84b8a110e550aab0c8fc957`, and both used the `WebView2UserData` profile, but the frontend state was different.

| Variable | Low diagnostic | Long diagnostic | Normal shell |
| --- | --- | --- | --- |
| Launch arguments | `--diagnostic-authenticated-no-bridges` | `--diagnostic-authenticated-no-bridges` | none |
| WebView2 options | remote debugging on port 9230 | remote debugging on port 9230 | default options |
| Profile | `WebView2UserData` | `WebView2UserData` | `WebView2UserData` |
| Reported route | `https://discord.com/app` | `https://discord.com/app` | route not independently captured |
| Display | 1920x1080 / 60 Hz | 1920x1080 / 60 Hz | 1920x1080 / 60 Hz |
| Exact channel/workload | not manually confirmed | not manually confirmed | not independently captured in the sample |
| Renderer lifetime/state | minimally initialized | substantially initialized | normal restored state |

The low observation had 2 documents, 1,084 DOM nodes, 15 MiB V8 used heap, zero image elements, and zero canvases. The long diagnostic had 10 documents, 5,196 DOM nodes, 100 MiB V8 used heap, 127 image elements, and 2 canvases. That frontend-state difference accounts for the observed memory gap far better than the launch argument or remote-debugging option, but it is not yet a causal proof.

The next controlled A/B must manually confirm the same static Discord channel and then compare normal versus diagnostic launch with only the diagnostic argument and CDP option changed. It must capture route, process lifetime, V8, DOM, images, canvases, GPU, and allocation-base groups in both states.
