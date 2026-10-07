# WebView2 memory API research, 2026-10-07

This note records the official WebView2 API surface relevant to Track B
memory attribution. Sources are Microsoft Learn pages linked below.

## Process attribution

`ICoreWebView2Environment8::GetProcessInfos` returns the processes using the
same WebView2 user-data folder, with process IDs and process kinds. Microsoft’s
sample then opens each process with `PROCESS_QUERY_LIMITED_INFORMATION` and
calls Windows `GetProcessMemoryInfo`, reading `PrivateUsage` for its displayed
memory value. The API therefore helps identify WebView2 roles, but it does not
provide a unique physical-resident total or replace the project’s
`VirtualQueryEx` and working-set measurements.

Track B will continue to use the rooted Windows process tree for total working
set, private working set, shareable working set, private bytes, faults, I/O,
handles, and threads. WebView2 process information can be used as a role/PID
cross-check when it is available.

The shell already has this cross-check behind diagnostic-only launch modes. It
calls `GetProcessInfos()` and `GetProcessExtendedInfosAsync()` and writes only
process ID, WebView2 kind, and associated frame count to the local diagnostic
file. The normal shell does not create this diagnostic file or enable remote
debugging. No additional host bridge is required for this part of attribution.

## MemoryUsageTargetLevel

Microsoft documents `CoreWebView2.MemoryUsageTargetLevel = Low` for inactive
WebViews. It is best-effort, may swap memory to disk, and can affect
performance when swapped pages are needed again. The documented guidance is to
restore `Normal` when the view becomes active.

Track B will not use this property for the active settled Discord view. It
would game the resident-memory KPI and could introduce page-fault or
responsiveness regressions. It may be evaluated later only as a separately
labeled minimized/inactive-state experiment with page-fault and responsiveness
measurements.

## ETW and DevTools

Microsoft recommends WebView2 ETW tracing with the WebView2 WPR profile and
Windows Performance Analyzer for CPU, disk, and memory analysis. It also
recommends Edge DevTools Memory and Performance tools for content-level
investigation. The current project already has the non-elevated Windows
sampler and CDP diagnostics; WPR remains an optional deeper trace when Windows
elevation is granted.

Sources:

- [ICoreWebView2Environment8](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2environment8?view=webview2-1.0.3912.50)
- [WebView2 performance best practices](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/performance)
- [CoreWebView2.MemoryUsageTargetLevel](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.memoryusagetargetlevel?view=webview2-dotnet-1.0.4129.50)
