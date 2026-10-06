# Track B decision 0020: WebView2 low-memory target is not the foreground solution

Date: 2026-10-06

## Decision

Do not set `CoreWebView2.MemoryUsageTargetLevel` to `Low` in the normal foreground shell or use it to claim progress toward the approximately 250 MiB settled-idle target.

It may be evaluated later as a separately labeled background/minimized-state experiment, with private-working-set, page-fault, responsiveness, notification, and wakeup measurements. It is not a renderer allocation fix.

## Why

Microsoft documents `Low` for inactive WebViews and describes the operation as best effort. The documentation also warns that memory may be swapped to disk and that later access can page it back in with a performance impact. That would change the resident-memory number through paging rather than reduce the resources required by Discord, and it could create the exact fault and responsiveness regressions the Track B acceptance criteria exclude.

The normal shell therefore remains at the default memory target. Renderer ownership and retained allocation must be reduced through measured frontend/runtime causes or a different architecture, not by forcing inactive-memory behavior on the active Discord view.

## Source

- [CoreWebView2.MemoryUsageTargetLevel](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/winrt/microsoft_web_webview2_core/corewebview2?view=webview2-1.0.3719.77)
- [WebView2 performance best practices](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/performance)
