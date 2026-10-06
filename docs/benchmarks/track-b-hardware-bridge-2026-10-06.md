# Track B hardware bridge diagnostic

Date: 2026-10-06

This is a diagnostic-only measurement of the narrow `DiscordNative.hardware.getDisplayCount` bridge. The shell loaded a local in-memory blank document, used the isolated `HardwareBridgeProbeUserData` profile, and was measured by root PID across all WebView2 child processes. No Discord account, route, network request, display name, or coordinate was read.

Three settled runs used 30 seconds of sampling at 5-second intervals. The bridge call returned the actual Windows display count (`2`) in each run and the root process remained responsive.

| Metric | Median | P95 | Notes |
| --- | ---: | ---: | --- |
| Summed working set | 368.40 MiB | 379.47 MiB | Includes all 7 processes |
| Private working set | 72.86 MiB | 74.20 MiB | Sum of process private working sets |
| Derived shareable working set | 295.54 MiB | 305.27 MiB | Working set minus private working set |
| Private bytes / commit | 145.75 MiB | 147.46 MiB | Process-tree sum |
| Total CPU | 0.020% | 0.020% | 16 logical processors |
| Process count | 7 | 7 | Root plus WebView2 helpers |

The prior three-run blank WebView2 floor had a 375.9 MiB median working set, 73.1 MiB median private working set, 145.3 MiB median private bytes, and 7 processes. The new bridge result is within run-to-run variation at this measurement duration, so no measurable aggregate resource cost is attributed to this capability. A longer paired baseline-versus-bridge test is still required before enabling it in normal mode.

Raw measurements remain private under `benchmarks/raw/track-b/` and are not published. This result does not establish that Discord’s frontend calls the capability or that desktop compatibility is complete.
