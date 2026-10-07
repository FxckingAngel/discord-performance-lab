# Official Discord read-only reference capture

This was a read-only observation of the already-running official Discord PTB
reference. No official process was stopped, restarted, moved, patched, or
reconfigured.

Raw evidence is local at:

`artifacts/official-reference-read-only-20261007.json`

The visible reference root was PID 36904 with the title `Friends - Discord`.
The capture lasted 30 seconds with six samples at five-second intervals.

## Complete-tree observation

| Metric | First sample | Last sample |
| --- | ---: | ---: |
| Total working set | 424.32 MiB | 449.45 MiB |
| Private working set | 325.98 MiB | 345.45 MiB |
| Private bytes | 908.61 MiB | 914.71 MiB |
| Process count | 6 | 6 |

Last-sample role breakdown:

| Role | Working set | Private working set | Private bytes |
| --- | ---: | ---: | ---: |
| Renderer | 340.88 MiB | 284.00 MiB | 523.16 MiB |
| GPU process | 54.57 MiB | 34.70 MiB | 231.49 MiB |
| Browser/native root | 34.14 MiB | 18.59 MiB | 120.46 MiB |
| Network service | 18.50 MiB | 7.43 MiB | 18.64 MiB |
| Audio service | 1.30 MiB | 0.65 MiB | 11.57 MiB |
| Crashpad | 0.07 MiB | 0.06 MiB | 9.40 MiB |

## Interpretation

This is current official-reference evidence, not a final Track A versus Track B
comparison. The exact route, account state, call state, and workload were not
independently confirmed during this capture. It establishes a fresh read-only
control observation for later same-display, same-route comparisons.

## Isolated clean-payload attempt

The signed official Windows payload was extracted to a private directory and
launched with a separate app-data tree. The child processes correctly used
that isolated tree, but startup stopped with `Cannot find module
'discord_desktop_core'`. The extracted package contains no
`discord_desktop_core` or other `discord_*` native module payload; those are
provided separately by the installed PTB distribution.

The failed isolated process tree was closed. No native modules were copied
from the active Vencord installation, so this attempt is not treated as a
pristine baseline or an official-versus-Track-B comparison.
