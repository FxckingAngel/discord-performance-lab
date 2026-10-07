# Track B authenticated renderer allocation-family lifecycle

Date: 2026-10-07  
Capture: `artifacts/track-b-lifecycle-fixed-20261007`  
Shell: Track B diagnostic authenticated build after the partial-bridge fix

## Scope

This report uses only checkpoints whose application-readiness gate passed. The endpoint-ready checkpoint is excluded because Discord had not populated `#app-mount` and therefore was not a valid loaded-state measurement.

No renderer behavior, media behavior, or cache policy was changed for this capture. The clean official Discord client was not modified.

## Lifecycle results

Values are for the renderer process identified by the capture. `Private writable` is committed private-writable resident memory from the read-only virtual-memory map. `Large regions` is the sum of the ranked large allocation-base families detected in that map. Addresses are process-specific and must not be compared across separate renderer lifetimes.

| Checkpoint | App ready | Renderer private WS (MiB) | Private writable resident (MiB) | Large regions (MiB) | Largest family (MiB) | 2nd (MiB) | 3rd (MiB) | V8 used (MiB) | DOM nodes |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| startup 5s | yes | 444.25 | 440.80 | 165.11 | 143.82 | 59.34 | 23.54 | 103.66 | 4,491 |
| startup 15s | yes | 354.86 | 352.36 | 16.64 | 64.74 | 25.53 | 17.75 | 102.60 | 4,502 |
| startup 30s | yes | 311.73 | 302.12 | 16.64 | 68.89 | 27.15 | 17.75 | 102.19 | 4,502 |
| startup 60s | yes | 296.88 | 294.00 | 16.64 | 68.76 | 27.93 | 17.75 | 104.55 | 4,498 |
| settled 3m | yes | 296.57 | 288.77 | 17.39 | 70.75 | 28.59 | 17.75 | 110.17 | 4,554 |
| settled 5m | yes | 299.11 | 306.02 | 63.43 | 80.44 | 62.88 | 17.75 | 98.33 | 4,612 |

The complete-tree private working-set values at the same valid checkpoints were 564.71, 471.13, 425.70, 408.31, 411.24, and 416.71 MiB respectively. The settled five-minute point therefore remains above the 250 MiB target and is not an acceptance pass.

## Interpretation

The first five-second valid state contains a large transient allocation family of about 143.82 MiB. By 15 seconds, that family has contracted and the ranked family total is only 16.64 MiB. This is evidence of lifecycle movement, not evidence that the family can be safely removed.

At three minutes the ranked families remain small, while the five-minute point shows two larger families again, approximately 80.44 MiB and 62.88 MiB. The capture does not yet establish whether this later growth is caused by normal Discord state, measurement variance, cache warming, media, or another workload transition.

The allocation bases are different between renderer lifetimes, so the current evidence supports rank- and size-based lifecycle tracking rather than address-based ownership claims. The report deliberately does not label these families as Blink, media, compositor, or WebView2 allocations.

The V8 values do not explain the renderer footprint by themselves. At five minutes, V8 used heap is about 98.33 MiB while renderer private writable resident memory is about 306.02 MiB. The remaining native/private portion must be investigated separately.

The CDP native-memory sampling window at the five-minute checkpoint contained only six samples and about 0.22 MiB of attributed bytes. It is insufficient to explain the retained renderer footprint and is not used as an ownership conclusion.

## Next evidence required

1. Repeat the valid canonical state with at least three settled repetitions and record the same lifecycle fields.
2. Add static-text versus media-heavy route transitions while preserving the readiness gate.
3. Track whether the later 80/63 MiB families expand with media and contract after returning to the canonical route.
4. Keep capability groups in the isolated compatibility harness until the sanitized vanilla startup call sequence identifies a coherent boot-critical contract.

No optimization is justified by this capture alone.
