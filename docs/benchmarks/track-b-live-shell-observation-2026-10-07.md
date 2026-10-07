# Track B live shell observation

Date: 2026-10-07

This was a live observation of the normal Release Track B shell after launch. The shell was not manually held at a named Discord route in this run, so this is current-state diagnostic evidence, not an authenticated acceptance benchmark.

The official Discord/Vencord installation was not stopped, restarted, or modified.

## Capture

- Root: normal `KoroneDiscordShell.exe` Release build
- Duration: 30.5 seconds
- Samples: 4, approximately 5 seconds apart
- Process count: 8 at every sample
- Display: 1920x1080 at 60 Hz
- Raw capture: retained outside the repository

| Sample | Total WS | Private WS | Private bytes |
| ---: | ---: | ---: | ---: |
| 1 | 1,035.64 MiB | 629.34 MiB | 856.00 MiB |
| 2 | 1,034.36 MiB | 618.89 MiB | 832.93 MiB |
| 3 | 1,025.01 MiB | 608.73 MiB | 820.50 MiB |
| 4 | 884.05 MiB | 468.46 MiB | 654.30 MiB |

The last sample is not a settled acceptance result. The drop between samples confirms that short fixed-delay measurements can observe refault and lifecycle settling rather than a stable workload baseline.

## Last-sample role breakdown

| Role | Private WS | Private bytes |
| --- | ---: | ---: |
| Renderer | 346.82 MiB | 388.71 MiB |
| GPU process | 46.72 MiB | 160.40 MiB |
| WebView2 browser | 45.40 MiB | 55.05 MiB |
| Native shell | 9.50 MiB | 13.03 MiB |
| Network service | 11.02 MiB | 16.34 MiB |
| Audio service | 3.63 MiB | 8.52 MiB |
| Storage service | 3.26 MiB | 8.87 MiB |
| Crashpad | 2.07 MiB | 3.37 MiB |

The renderer remains the largest private-resident owner. This observation does not identify which renderer allocation class is reclaimable, and it does not justify disabling media, GPU acceleration, or normal Discord features. The next valid comparison remains a fixed manually confirmed route with a longer settle condition and repeated samples.
