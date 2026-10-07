# Track B WebView2 memory-control research

Date: 2026-10-06

Sources: Microsoft Edge WebView2 performance guidance, WebView2 memory-usage target API documentation, WebView2 process-model FAQ, and WebView2 browser-flags documentation.

## Findings

1. A WebView2 control creates browser, renderer, GPU, and utility processes. Microsoft recommends sharing one environment when an application has multiple controls. Track B currently uses one control, so environment sharing cannot remove the current renderer's private allocation.
2. `MemoryUsageTargetLevel = Low` is intended for inactive WebViews. Microsoft states that it can cause memory to be swapped to disk and can affect performance when the WebView becomes active again. It is therefore not an acceptable way to meet Track B's settled-idle resident-memory target and is not enabled.
3. `TrySuspendAsync()` is also an inactive-WebView lifecycle control. It is suitable for a genuinely suspended background surface, not for a normal settled Discord window that must remain immediately functional.
4. Microsoft advises keeping hardware acceleration enabled for normal rendering and describes disabling GPU as a troubleshooting action. Track B's existing GPU-disabled experiment therefore remains diagnostic evidence, not a candidate optimization.
5. Microsoft notes that high resource use is often caused by the rendered web content rather than by the WebView2 control alone. This is consistent with Track B's blank-floor versus authenticated renderer delta and supports continuing renderer feature attribution.

## Decision

No WebView2 memory flag is adopted. Any future candidate must reduce actual resident allocation without forcing paging, suspending the active Discord surface, disabling hardware acceleration, or removing Discord functionality. The current renderer-native breakdown remains the gate for selecting a real optimization.

## References

- https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/performance
- https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/winrt/microsoft_web_webview2_core/corewebview2memoryusagetargetlevel
- https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/end-user-faq
- https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/webview-features-flags
