# Track B autofill control

Date: 2026-10-06

The shell briefly tested WebView2 general autofill disabled, based on Microsoft's documented default of enabled. The change was removed after the short control showed no improvement and substantially worse settling behavior.

The 124.7-second run measured 506.38 MiB median private working set, 705.00 MiB median private bytes, and 1.185% total CPU. Its first sample was still at 1,183.1 MiB private bytes, so it is not a clean comparison with the settled 10-minute baseline. It nevertheless provides no evidence of a useful reduction, and disabling a browser convenience feature without a measured benefit would be an unjustified behavior change.

Decision: reject and revert. The normal shell retains WebView2's default autofill behavior and no autofill-related optimization is claimed.

Input: `benchmarks/raw/track-b-autofill-off-120s-summary-20261006.json`
