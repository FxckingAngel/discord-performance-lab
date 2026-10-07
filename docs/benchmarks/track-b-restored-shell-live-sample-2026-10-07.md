# Track B restored-shell live sample

Date: 2026-10-07

After the synchronized authenticated CDP diagnostic was closed normally, the standard shell was restored and observed for a 30-second Windows process-tree sample. The restored shell was responsive and retained the normal prototype title.

| Metric | Result |
| --- | ---: |
| Complete-tree private working set median | 449.75 MiB |
| Complete-tree private working set p95 | 568.34 MiB |
| Renderer private working set median | 331.52 MiB |
| Complete-tree private bytes median | 658.78 MiB |
| CPU median | 0.449% |
| CPU p95 | 1.252% |
| Process count | 8 |
| Current renderer PID | 39756 |

This is not an acceptance baseline. The shell had just been restored, and the 30-second interval is shorter than the canonical five-repetition benchmark. It demonstrates that renderer lifetime and settlement state materially affect the measured result. The stored native WebView2 inventory still contained the earlier diagnostic renderer PID, so it was not used for this restored-shell mapping.

No feature was disabled and no renderer behavior was changed.
