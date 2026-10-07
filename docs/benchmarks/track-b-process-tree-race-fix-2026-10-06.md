# Track B process-tree sampler race fix

Date: 2026-10-06

The 120-second post-build capture initially failed because a WebView2 child exited between the rooted-process enumeration and `Get-Process` inspection. The sampler previously ignored only one exception type, so the transient child exit invalidated the complete run.

The sampler now ignores only per-process query errors whose messages identify a missing or already-terminated process and still rethrows unrelated errors. A 30-second real capture after the change completed with six samples:

- first working set: 532.7 MiB
- last working set: 532.5 MiB
- first private bytes: 257.5 MiB
- last private bytes: 257.3 MiB

Raw capture: `benchmarks/raw/track-b-race-safe-smoke-20261006.json`.

This is a benchmark reliability fix, not a resource optimization. Child process churn remains visible through process counts and per-sample rows where the child is present.
