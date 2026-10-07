# Track B paired renderer boundary capture, 2026-10-07

The new boundary-capture wrapper selected the renderer from the rooted Track B
tree before measuring its resident pages. This avoids manually matching a PID
from a previous capture. The capture was read-only and used the already-running
Verified shell at root PID 39116.

Source artifacts:

- `artifacts/track-b-renderer-boundary-paired-20261007/boundary-capture.json`
- `artifacts/track-b-renderer-boundary-paired-20261007/virtual-types.json`
- `artifacts/track-b-renderer-boundary-paired-20261007/renderer-resident-types.json`
- `artifacts/track-b-renderer-boundary-paired-20261007/renderer-ledger.json`

The rooted tree contained eight processes and the selected renderer was PID
28160.

| Renderer category | MiB |
| --- | ---: |
| Resident working set | 378.734 |
| Private writable resident | 281.379 |
| Image-backed resident | 75.457 |
| Mapped resident | 20.816 |
| Committed private writable | 330.109 |
| Committed private writable not resident | 48.730 |

The virtual and resident queries are sequential read-only calls, not a single
atomic Windows snapshot. The renderer PID is selected from the rooted tree
before both queries, and the manifest preserves that mapping. The ledger keeps
resident and committed categories separate and excludes reserved address space
from the RAM target.

No Discord behavior, authentication state, network behavior, or shell settings
were changed.
