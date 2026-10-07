# Experiment 011: WebView2 memory target level

## Decision

Do not add `CoreWebView2.MemoryUsageTargetLevel = Low` to the production shell or use it in the primary benchmark.

## Reason

Microsoft documents the property for inactive WebViews and says that the low level is a best-effort request. Its documentation also warns that setting the low level can cause memory for WebView browser processes to be swapped to disk. That would lower a resident-memory reading without reducing the resources the application actually needs and could create page-fault or responsiveness regressions.

The Track B target is a settled foreground target across the complete process tree. A minimized-only memory hint would not reduce the foreground renderer allocation identified by the visibility isolation run. It would also complicate the interpretation of the no-page-out benchmark rule.

## Evidence and source

The visibility isolation measurement found that minimizing the same shell lowered private bytes by 16.83 MiB, almost entirely in the renderer. The production target remains the visible foreground state.

Microsoft's [CoreWebView2.MemoryUsageTargetLevel documentation](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.memoryusagetargetlevel) says scripts continue to run, describes the property as best effort, and warns about possible swapping when the low level is used.

No code was changed for this experiment.
