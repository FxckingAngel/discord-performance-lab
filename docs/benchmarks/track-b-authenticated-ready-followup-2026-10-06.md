# Track B authenticated checkpoint follow-up: extended settled state

This follow-up continued observing the same user-confirmed Track B session after the 600-second checkpoint and a fallback Windows counter capture. No window input, Discord state, account data, or process settings were changed.

## Direct process-tree result

- Root PID: 25772
- Duration: 184.763 seconds
- Samples: 6 at 30-second intervals
- Process tree: seven processes in every sample
- Raw sample: `benchmarks/raw/track-b-authenticated-ready-followup-180s-20261006.json`

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 513.29 MiB | 513.32 MiB |
| Private working set | 151.53 MiB | 151.55 MiB |
| Private bytes / commit | 241.63 MiB | 241.69 MiB |
| Total CPU | below sampler display resolution | below sampler display resolution |

The lower private-memory state persisted across the follow-up window. The renderer was 104.77 MiB private bytes, the GPU process 58.50 MiB, and the WebView2 browser process 42.04 MiB in the final sample.

## Counter attribution

The fallback counter capture ran for 63.849 seconds over 13 scheduled samples. Windows returned complete process rows for 10 samples. A synchronized WMI/Get-Counter cross-check immediately afterward matched exactly:

- private working set: 151.516 MiB versus 151.531 MiB;
- private bytes: 241.617 MiB versus 241.633 MiB.

The fallback counters reported 0% median GPU engine utilization, 17.49 MiB median dedicated GPU memory, 0 bytes/sec median disk read and write I/O, and low intermittent page-fault activity. Missing rows were preserved as unavailable in the raw artifact rather than converted to zero.

## Interpretation

This is the first post-checkpoint observation below the approximately 250 MiB private-bytes target. It is evidence that the same shell can reach the target after additional natural settling, not evidence that a code change reduced memory. The preceding 600-second run was higher at 257.05 MiB median private bytes, so the target still needs repeated controlled runs before it can be treated as a stable acceptance result.

Windows rejected the attempted WPR start with `0xc5585011` because the local session lacks the policy required for system performance recording. No profiling policy was changed. The read-only counter sampler remains the available fallback, without ETW stack or context-switch attribution.
