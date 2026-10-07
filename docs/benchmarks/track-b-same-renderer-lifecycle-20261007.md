# Track B navigation lifecycle memory capture

Date: 2026-10-07

This capture followed one Track B diagnostic shell through an authenticated Discord route, `about:blank`, and restoration of the Discord route. It was intended to test whether the renderer process survives navigation. The shell used the existing authenticated profile and no capability bridges. Official Discord was not touched.

Raw process-tree and CDP files remain private under `artifacts/track-b-same-renderer-20261007/`.

## Result

Navigation did not preserve one renderer process. The renderer PID changed at both transitions:

| State | Process-tree renderer PID | Process count | CDP targets |
| --- | ---: | ---: | ---: |
| Discord route before transition | 56136 | 8 | 3 |
| `about:blank` | 8872 | 8 | 1 |
| Discord route restored | 53908 | 8 | 3 |

The process count stayed at eight, but renderer identity did not. This means the capture is a useful lifecycle boundary, not a same-renderer retention experiment. Future lifecycle tooling must capture CDP process identity at every checkpoint and classify the corresponding renderer PID before comparing allocation families.

The follow-up live probe after adding per-state process mapping captured six CDP processes at each checkpoint and reported renderer IDs `13244`, `53804`, and `55236` for loaded, blank, and restored states respectively. The IDs changed in the same pattern. The probe wrote only aggregate process roles, IDs, and CPU counters; no page content or command lines were exported.

## Process-tree medians

Each state used four process-tree samples. These are diagnostic medians, not an acceptance baseline.

| State | Total working set | Private working set | Private bytes | Renderer working set | Renderer private working set |
| --- | ---: | ---: | ---: | ---: | ---: |
| Discord route before transition | 1,020.75 MiB | 620.44 MiB | 850.18 MiB | 608.45 MiB | 499.78 MiB |
| `about:blank` | 466.32 MiB | 131.94 MiB | 316.63 MiB | 44.83 MiB | 9.77 MiB |
| Discord route restored | 959.87 MiB | 546.74 MiB | 745.65 MiB | 538.94 MiB | 427.79 MiB |

The restored route was lower than the pre-transition sample but remained far above the blank state. The spread is consistent with the previously observed authenticated-state variance and does not prove that navigation released a particular allocation family.

## CDP state comparison

The CDP diagnostic was collected separately at each state. It reported:

| State | V8 used heap | V8 total heap | V8 backing storage | DOM nodes | Documents | JS listeners |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Discord route before transition | 115.65 MiB | 208.76 MiB | 27.84 MiB | 6,395 | 13 | 2,350 |
| `about:blank` | 0.50 MiB | 1.00 MiB | 0 MiB | 8 | 2 | 0 |
| Discord route restored | 116.85 MiB | 214.38 MiB | 23.87 MiB | 6,296 | 14 | 2,384 |

The restored route recreated a similar JavaScript state, while the renderer process itself was new. This confirms that the large loaded-state footprint is acquired again during Discord navigation; it does not yet identify which native allocation family owns it.

The restored renderer's read-only virtual-memory classification reported 444.84 MiB resident, including 328.22 MiB private-writable resident and 358.03 MiB committed private-writable memory. The large private-writable buckets were 43.59 MiB below 64 KiB, 76.51 MiB from 64 KiB to 1 MiB, 59.05 MiB from 1 MiB to 4 MiB, 108.18 MiB from 4 MiB to 16 MiB, and 40.89 MiB at 16 MiB or larger.

## Interpretation and next tooling change

This result answers one open question: a simple CDP navigation to blank does not keep the Discord renderer alive. It also shows that returning to the route reacquires a large renderer footprint and similar V8/DOM state. It does not support calling that footprint a retained cache or a fixed WebView2 floor.

The next lifecycle harness must:

1. capture `SystemInfo.getProcessInfo` and the Windows process tree at every checkpoint;
2. join CDP and Windows rows by PID before classifying memory;
3. preserve renderer identity changes as a transition rather than aggregating them as one renderer;
4. compare blank, authenticated route, media-heavy route, and returned static route with the same per-PID ledger.

The navigation probe now records `SystemInfo.getProcessInfo` at each state and has a regression check for the process-map fields. A live run confirmed that the state-level renderer identity change is observable through CDP as well as through the Windows process tree.

No renderer behavior was changed. No visible Discord feature was disabled, and no trimming, forced paging, or forced garbage collection was used.
