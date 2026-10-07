# Track B same-build blank floor follow-up

This control launched the verified shell with `--diagnostic-blank` in its separate runtime profile. It did not load Discord, reuse account content, or change the normal authenticated shell. The diagnostic closed through its normal window-close path and left no matching helper processes.

## Results

| Metric | Median |
| --- | ---: |
| Complete-tree private working set | 71.75 MiB |
| Complete-tree total working set | 359.98 MiB |
| CPU | 0.016% |
| Renderer private working set | 9.77 MiB |
| Browser private working set | 28.73 MiB |
| GPU private working set | 14.48 MiB |
| Native shell private working set | 8.22 MiB |

There were 7 samples over approximately 30 seconds. Compared with the current 60-second loaded observation of 371.23 MiB complete-tree private working set, this control implies an approximately 299.48 MiB loaded-state private-resident delta. The delta is Discord-dependent evidence, not a claim that all of it is reclaimable or that it belongs to JavaScript.

## Interpretation

The same-build WebView2 runtime floor is well below the 250 MiB target under private-working-set accounting. The remaining gap is therefore primarily in the loaded Discord renderer/application state and must be decomposed through lifecycle and route comparisons. The result does not justify disabling features, changing renderer process behavior, or applying launch flags.

Raw artifacts remain local under `artifacts/track-b-blank-floor-followup-20261007/`.
