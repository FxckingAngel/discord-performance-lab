# Decision 0006: do not use unmeasured WebView2 flags to chase the RAM target

Date: 2026-10-06

## Decision

Track B will not add `--disable-features`, sandbox switches, media switches, storage switches, or other Chromium arguments to reduce the settled-memory number unless a specific allocation or behavior has first been measured and the corresponding Discord scenario has a feature test.

The normal shell continues to use the WebView2 defaults. Diagnostic-only remote debugging remains limited to explicitly named diagnostic modes.

## Evidence

The current authenticated manual checkpoint measured the complete Track B tree at:

- 163.15 MiB median private working set, 163.97 MiB P95;
- 255.80 MiB median private bytes, 256.69 MiB P95;
- 528.96 MiB median summed working set;
- 0.002% median and P95 total CPU;
- seven processes.

The private-bytes result is close to the approximately 250 MiB design target. The process roles show no single small service that can account for the remaining difference: renderer 119.62 MiB, GPU 58.52 MiB, browser 53.84 MiB, network 13.29 MiB, storage 7.64 MiB, and crashpad 2.89 MiB private bytes.

Microsoft's WebView2 documentation describes `AdditionalBrowserArguments` as a behavior-changing mechanism and states that switches important to WebView functionality may be ignored or blocked. A flag that lowers one process metric without a matching Discord feature test would therefore be weak evidence and could silently remove storage, media, security, or notification behavior.

Source: [CoreWebView2EnvironmentOptions documentation](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/winrt/microsoft_web_webview2_core/corewebview2environmentoptions?view=webview2-winrt-1.0.1343.22)

## Current-state supersession

The checkpoint above is historical and state-specific. Later rebuilt-shell measurements are the current reporting authority: repeated blank-shell private working set was 74.05 MiB median, authenticated no-bridge private working set was 608.82 MiB median, and a later live settled shell was 412.94 MiB median with the renderer at about 303 MiB private working set. These later results do not invalidate the no-unmeasured-flags decision, but they do leave the approximately 250 MiB target unresolved and prevent the earlier near-target session from being treated as a general pass.

## Consequence

WebView2 remains an investigated candidate, not a validated architecture. The target is not lowered. Further work should prioritize authenticated feature parity, allocation attribution, and a measured native/runtime comparison rather than random scheduling or Chromium flags.
