# Track B decision 0013: do not use WebView2 low-memory mode for settled idle acceptance

Date: 2026-10-06

## Decision

Do not set `CoreWebView2.MemoryUsageTargetLevel` to `Low` in the normal foreground shell or use it to satisfy the 250 MiB resident-memory target.

## Reason

Microsoft documents this property as a best-effort hint for inactive WebViews. The low setting can cause browser-process memory to be swapped to disk, and returning to active use can page that memory back in. That would lower resident memory without reducing the resources required by Discord and could introduce page-fault or responsiveness regressions.

The Track B target requires a real reduction in required resources. A low-memory policy may be useful for a separately measured minimized/background profile in the future, but it cannot be used for settled foreground acceptance and must not be enabled by default.

## Evidence boundary

No code change was made. The known-good normal shell remains at its existing memory policy. Any future inactive-state experiment must report page faults, I/O, wakeups, responsiveness, and restoration to normal before it can be considered.

## Source

Microsoft Learn, `CoreWebView2.MemoryUsageTargetLevel`: https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.memoryusagetargetlevel?view=webview2-dotnet-1.0.4129.50
