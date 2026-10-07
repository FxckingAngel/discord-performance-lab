# Track B desktop-identity sample

This is a post-build smoke sample of the normal Track B shell after applying the audited Discord Desktop user-agent identity to the production WebView2 settings. It is not an authenticated same-route acceptance benchmark.

## Result

The shell stayed responsive for 60.437 seconds with eight processes. Across 11 samples, complete-tree private working set was 392.10–446.35 MiB, with a median of 409.12 MiB and an estimated p95 of 446.35 MiB. Private bytes had a median of 566.09 MiB and an estimated p95 of 612.06 MiB. The renderer was the largest private-resident process in the sample.

The sample includes startup settling and does not establish the canonical authenticated idle baseline. It is evidence that the desktop identity change did not prevent the shell from running, not evidence of a performance improvement.

## Scope and safety

The change is limited to the WebView2 user-agent identity. The shell does not expose `DiscordNative` in the normal path, and it does not alter authentication, authorization, entitlements, network protocol, or security behavior. Unsupported desktop capabilities remain unclaimed.

Raw process data remains under `artifacts/track-b-desktop-identity-sample-20261007/` and is not publication-safe.

## Verification

- Release build succeeded.
- Performance-tool test passed.
- Track B shell smoke test passed for blank, capability-events, and normal single-instance cases.
- Normal shell launched and remained responsive after the change.
- Official Discord was not stopped or restarted.
