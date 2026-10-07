# Track B Verified blank runtime floor

The rebuilt `bin/Verified/KoroneDiscordShell.exe` was launched in `--diagnostic-blank` mode while the existing normal Release shell remained active. This is a runtime-floor measurement only and does not represent a Discord workload.

Artifact: `artifacts/track-b-verified-blank-floor-20261007/process-tree.json`

Six samples were collected from root PID `12848`.

| Metric | Median |
| --- | ---: |
| Process count | 7 |
| Total working set | 359.62 MiB |
| Private working set | 71.07 MiB |
| Private bytes | 144.58 MiB |

The diagnostic process closed normally and the existing Release shell was not changed. The floor leaves roughly 179 MiB of private working-set budget below the 250 MiB Track B target, but loaded Discord state must still be measured with the same binary before drawing an architecture conclusion.
