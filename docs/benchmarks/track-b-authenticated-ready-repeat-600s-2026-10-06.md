# Track B authenticated checkpoint repeat: 600-second settled observation

This is a second full-duration observation of the same user-confirmed Track B session. The sampler did not control the native window, send input, or change Discord state. Account and route identity remain user-confirmed rather than independently inspected.

## Conditions

- Root PID: 25772
- Duration: 621.204 seconds
- Samples: 20 at 30-second intervals
- Process tree: seven processes in every sample
- Raw sample: `benchmarks/raw/track-b-authenticated-ready-repeat-600s-20261006.json`

## Results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 513.26 MiB | 513.84 MiB |
| Private working set | 151.24 MiB | 151.65 MiB |
| Private bytes / commit | 241.61 MiB | 241.70 MiB |
| Total CPU | approximately 0% at median sampler resolution | 0.00635% |

The result stayed below the approximately 250 MiB private-bytes target for the full capture. It also remained below the 0.2% CPU target. The earlier 600-second checkpoint was higher at 257.05 MiB median private bytes, so this repeat confirms a lower settled state after additional natural settling but does not identify a code change as its cause.

## Role attribution

| Role | Private working set median | Private bytes median |
| --- | ---: | ---: |
| Renderer | 86.76 MiB | 104.77 MiB |
| GPU process | 14.93 MiB | 58.55 MiB |
| WebView2 browser | 30.20 MiB | 41.98 MiB |
| Network service | 7.25 MiB | 13.11 MiB |
| Native shell | 7.83 MiB | 12.64 MiB |
| Storage service | 2.93 MiB | 7.68 MiB |
| Crashpad | 1.32 MiB | 2.89 MiB |

## Acceptance status

The resource target is now repeatedly observed in the same prepared session. This is not the final Track B acceptance result: visual parity, the complete manual functional checklist, and a controlled official-versus-Track-B same-route comparison remain open. No functionality was removed, no memory trimming was used, and no unmeasured Chromium switch was added.
