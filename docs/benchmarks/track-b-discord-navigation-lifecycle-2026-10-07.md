# Track B same-renderer Discord navigation lifecycle

This read-only probe ran inside the isolated unauthenticated `--diagnostic-discord` profile on loopback CDP. It navigated the same renderer to `about:blank`, waited five seconds, and restored the original Discord URL locally. The original URL was not written to the output. The normal authenticated shell was not modified.

## Aggregate CDP states

| State | V8 used | V8 total | DOM nodes | Frames | Documents | Listeners | Images | Canvases |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Discord before transition | 19.40 MiB | 20.68 MiB | 1,035 | 1 | 2 | 0 | 0 | 0 |
| Same renderer on blank | 0.50 MiB | 1.00 MiB | 3 | 1 | 2 | 0 | 0 | 0 |
| Discord restored after 5 seconds | 58.32 MiB | 98.22 MiB | 1,237 | 2 | 22 | 1,123 | 3 | 2 |

## Interpretation

The renderer can release most measured V8 and document state when navigated to a blank page, so the loaded memory is not a fixed JavaScript heap floor. The restored Discord state had not necessarily reached its final settled state after five seconds, and this probe did not collect synchronized process-private-working-set samples at each transition. It therefore identifies a lifecycle signal, not a reclaimable optimization owner.

The unexpected increase in frames, documents, listeners, images, and canvases after restoration makes longer settled lifecycle checkpoints important before selecting an application-state or document-retention hypothesis. No production renderer behavior was changed.

Raw artifact remains local at `artifacts/track-b-discord-navigation-20261007.json`.
