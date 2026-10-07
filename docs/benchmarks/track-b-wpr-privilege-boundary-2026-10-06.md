# Track B WPR privilege boundary

Date: 2026-10-06

Windows Performance Recorder is installed at `C:\Windows\System32\wpr.exe`. The available built-in `CPU.Verbose` and `ResidentSet.Verbose` profiles expose the requested CPU sampling, context-switch, hard-fault, disk-I/O, virtual-allocation, and resident-set providers.

Starting a trace from the current non-elevated process was denied with:

`0xc5585011: Failed to enable the policy to profile system performance.`

The non-elevated attempt did not leave a trace session running. An explicitly elevated retry through `tools/Run-TrackBWprCapture.ps1` succeeded later the same day. The resulting status record reports `elevated=true`, `started=true`, `startCode=0`, and `stopCode=0`; the private ETL is recorded in `artifacts/track-b-wpr-elevated-20261006/track-b-cpu-resident.etl`.

The ETL is preserved as raw diagnostic evidence. This machine has `wpr.exe` but no WPA or `wpaexporter.exe`, so the trace has not been decoded into scheduler, stack, or resident-set tables here. It must not be treated as analyzed evidence until an ETL reader is available. The read-only process-tree, VirtualQueryEx/QueryWorkingSetEx, and CDP measurements remain the decoded evidence sources.
