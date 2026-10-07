# Track B live WebView2 process inventory refresh

Date: 2026-10-07

The native shell now subscribes to WebView2 `CoreWebView2Environment.ProcessInfosChanged` and refreshes the local sanitized process inventory whenever the WebView2 process collection changes. The initial inventory is also written for the normal shell, not only diagnostic modes.

Microsoft documents `ProcessInfosChanged` as the event raised when a WebView2 process is detected or exits, and `GetProcessInfos()` as the current process collection. Source: Microsoft Learn, `CoreWebView2Environment` reference.

Verification after rebuilding and relaunching the standard shell:

| Source | Renderer PID |
| --- | ---: |
| Windows process-tree attribution | 40684 |
| Fresh WebView2 process inventory | 40684 |

The Windows tree contained 8 processes. WebView2 reported 7 because its process inventory excludes crashpad. The inventory timestamp was refreshed at the same launch as the current renderer. The change is diagnostic bookkeeping only: it does not inject page code, alter Discord requests, change authentication, disable features, or change renderer scheduling.

Build succeeded with the repository's existing WindowsBase reference warning. `Test-DiscordPerformanceTools.ps1` passed, and `git diff --check` reported no whitespace errors.
