# Track B evidence status

This file distinguishes historical measurements from evidence that can support current acceptance decisions. Historical files are retained.

## Current acceptance authority

- The primary idle RAM metric is complete-tree private working set, treated as the closest available unique/private resident measure.
- Total working set, derived shareable working set, and private bytes/commit remain separate reported metrics.
- The idle target is approximately 250 MiB private working set and 0.2% median CPU.
- Active-workload RAM limits remain unset until pristine Official Discord same-workload baselines exist.
- A result must pass the fully initialized gate: stable renderer PID, synchronized WebView2 inventory, manually confirmed exact route, visibly loaded frontend, completed navigation, stable process count, and unchanged route during capture.

## Superseded or non-comparable results

The following evidence remains useful for history or diagnosis but must not be presented as a general Track B performance win:

| Evidence | Status | Reason |
| --- | --- | --- |
| Approximately 113 MiB authenticated diagnostic state | Initialization diagnostic only | Two documents, about 1,084 DOM nodes, no images/canvases, and much smaller V8 state; not fully initialized Discord |
| Older approximately 160–180 MiB private-working-set reports | Verify individually before citation | Route, frontend initialization, and workload equivalence were not consistently established |
| Earlier approximately 243 MiB private-bytes prepared-session result | Historical, state-specific | Private bytes are not the primary RAM KPI and the state was not proven equivalent to the current fully initialized workload |
| Official Discord comparisons from the current PTB installation | Official Discord + Vencord | The installation is Vencord-patched and cannot isolate an Electron or desktop-container tax |
| Blank or unauthenticated WebView2 results | Runtime/feasibility diagnostics | They do not represent normal authenticated Discord use |

## Current diagnostic direction

The latest automated five-repeat unverified Track B run measured 357.27 MiB median complete-tree private working set and 0.033% median CPU. It is tighter evidence than the earlier failed run, but it did not pass the manual route checkpoint. The renderer's largest private-writable allocation-base family varied from roughly 56 to 90 MiB across repetitions. That family remains an attribution target, not a named cache or approved optimization.
