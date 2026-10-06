# Track B WPR availability check: 2026-10-06

Windows Performance Recorder is installed at `C:\Windows\system32\wpr.exe` and exposes built-in CPU, ResidentSet, DiskIO, GPU, and Handle profiles.

The attempted non-invasive session was rejected before recording began:

```text
Failed to enable the policy to profile system performance.
Error code: 0xc5585011
```

No `.etl` trace was created, no system policy was changed, and the Track B shell was unaffected. The current non-elevated session cannot use WPR for ETW attribution. Continue using the existing read-only process counters, PSAPI working-set classification, virtual-memory classification, and aggregate CDP diagnostics unless the user separately authorizes an elevated WPR session.
