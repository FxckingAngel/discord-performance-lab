# Track B authenticated Friends paired control

Date: 2026-10-07  
Official reference: isolated vanilla PTB 1.0.1223, Electron 42.11.10  
Track B: current Release shell with verified desktop client hints  
Display: 1920x1080 at 60 Hz  
Metric: summed private working set across the measured process tree

## Route state

The isolated official reference was manually authenticated and independently confirmed at `https://ptb.discord.com/channels/@me` with the page title `Friends`. Its profile remained separate from the active Vencord installation.

Track B was measured from its existing authenticated WebView2 profile. Its route was not independently exposed through CDP during this capture, so this is a paired authenticated-profile diagnostic, not the final same-route acceptance baseline.

## Measurement

Each side used ten samples at five-second intervals after launch or settling.

| Client | Complete-tree private working set | Renderer private working set | CPU median | CPU p95 | Processes |
|---|---:|---:|---:|---:|---:|
| Official vanilla | 516.62–548.05 MiB, median 539.56 | median 378.99 MiB | 0.395% | 0.914% | 6 |
| Track B | 440.00–461.78 MiB, median 447.31 | median 343.89 MiB | 0.194% | 0.538% | 8 |

Track B was 92.25 MiB lower at the paired median, or approximately 17.1% below this control. Because the route/state pairing is not yet independently verified on both sides, this percentage is diagnostic only and must not be used as the final product claim.

## Interpretation

The result is evidence that the current Track B shell can use less private resident memory than the isolated official build while retaining a multi-process Discord state. It does not prove the 250 MiB target, visual parity, or feature parity. Track B remains approximately 197 MiB above the target at this median.

The next acceptance run must expose a sanitized route class from Track B as well as the official reference, keep the same `Friends` route and window state, and repeat the comparison after a fixed settle condition. No functionality was disabled and no working-set trimming or forced collection was used.
