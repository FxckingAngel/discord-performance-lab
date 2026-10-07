# Track B authenticated checkpoint: 600-second observation

The user confirmed `READY` after leaving the existing Track B shell in the requested authenticated state. This capture observed the existing process tree without controlling the native window or reading account content. The exact route and account state therefore remain user-confirmed rather than independently inspected by the benchmark.

## Conditions

- Build: verified Track B shell
- Root PID: 25772
- Duration: 621.311 seconds
- Samples: 20 at 30-second intervals
- Process tree: seven processes in every sample
- Window: existing shell left running
- Raw sample: `benchmarks/raw/track-b-authenticated-ready-600s-20261006.json`

## Results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 528.57 MiB | 534.69 MiB |
| Private working set | 165.85 MiB | 179.79 MiB |
| Private bytes / commit | 257.05 MiB | 257.66 MiB |
| Total CPU | approximately 0% at median sampler resolution | 0.0127% |
| Handles | 3,569 | 3,587 |
| Threads | 174 | 187 |

The process tree remained stable at seven processes. The final role mapping was one native shell, one browser process, one renderer, one GPU process, two utility services, and one crashpad handler.

## Private-byte role attribution

| Role | Private working set median | Private bytes median |
| --- | ---: | ---: |
| Renderer | 100.78 MiB | 119.80 MiB |
| GPU process | 14.97 MiB | 58.57 MiB |
| WebView2 browser | 30.84 MiB | 42.27 MiB |
| Network service | 7.37 MiB | 13.19 MiB |
| Native shell | 8.09 MiB | 12.68 MiB |
| Storage service | 3.03 MiB | 7.71 MiB |
| Crashpad | 1.37 MiB | 2.89 MiB |

## Status

This run clears the settled private-working-set subgate and the 0.2% CPU target. It does not meet the approximately 250 MiB private-bytes design target: the median is about 7.05 MiB above it. The result is a resource checkpoint, not proof of visual parity, feature completeness, or an official-quality build. The next engineering work remains renderer/GPU attribution and safe, measured reductions rather than unmeasured flags, forced trimming, or functionality removal.
