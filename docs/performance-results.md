# Discord Performance Lab: Results

## Status

Research concluded. These are sanitized aggregate results from the Track A official-Discord reference work and Track B native Windows/WebView2 shell work. Raw ETL, heap snapshots, profiles, screenshots, account data, private URLs, and local machine paths are not included.

All memory figures below use private working set unless the metric is explicitly named otherwise. Process-tree figures include the shell and WebView2/Chromium helper processes. Results from the user's Vencord installation are labeled accordingly and were not used to claim a pristine Electron comparison.

## Matched Friends-route comparison

| Metric | Pristine official Discord | Track B |
| --- | ---: | ---: |
| Complete-tree private working set | 539.56 MiB | 483.14 MiB |
| Renderer private working set | 378.99 MiB | 370.68 MiB |

Track B reduced the matched complete-tree result by approximately 56.42 MiB, or 10.5%. Renderer memory remained close to official Discord. This indicates that replacing the surrounding Electron shell removes some overhead, but does not remove the largest initialized Discord frontend and rendering cost.

## Track B runtime and loaded-state results

| State or run | Complete-tree private working set | Renderer private working set | V8 used heap | GPU private working set | CPU |
| --- | ---: | ---: | ---: | ---: | ---: |
| Blank WebView2 floor | 71.75 MiB | — | — | — | — |
| Blank WebView2 floor, later corrected run | 72.6 MiB | — | — | — | — |
| Discord unauthenticated | 330.93 MiB | — | — | — | — |
| Discord authenticated diagnostic state | 371.23 MiB | 252.18 MiB | 24.07 MiB | — | — |
| Fully loaded normal-shell reference | about 399–407 MiB | about 294–299 MiB | — | — | within idle target |
| Valid fully initialized baseline | about 419 MiB | about 313 MiB | about 113 MiB | about 37 MiB | about 0.108% |
| Lower settled fully initialized capture | 310.18 MiB | 254.92 MiB | — | — | 0.016% median |

The blank shell is far below the 250 MiB design target. The Discord frontend and its native rendering state add most of the remaining memory. The 250 MiB target was not reached while retaining normal Discord behavior, media quality, hardware acceleration, authentication, and security boundaries.

## Process and memory decomposition

One corrected eight-process capture reported:

| Component | Private working set |
| --- | ---: |
| Complete process tree | 407.32 MiB |
| Renderer | 301.89 MiB |
| GPU process | 39.39 MiB |
| WebView2 browser process | 38.65 MiB |
| Native shell | about 8 MiB |

The same capture reported 586.62 MiB private bytes, 0.085% median CPU, and 0.428% CPU p95. Private bytes are committed private memory, not resident RAM, and are reported separately from private working set.

Other synchronized renderer captures reported:

- 287 MiB renderer private working set with 106.15 MiB V8 used heap and 0.108% median CPU.
- 321.62 MiB private-writable resident memory with 101.19 MiB V8 used heap, leaving about 220.41 MiB outside measured V8. Three large anonymous allocation-base groups accounted for about 140.95 MiB resident memory.
- 354 MiB renderer private resident memory with about 113 MiB V8 and a largest native allocation family of about 146 MiB.

These results show that the remaining renderer footprint is primarily non-V8 native, Blink, compositor, image/media, or runtime memory. The measurements do not justify calling the full renderer footprint JavaScript memory.

## CPU results

Idle CPU reached the target in controlled runs:

- Approximately 0.016% median in one settled capture.
- Approximately 0.085% median with 0.428% p95 in an eight-process capture.
- Approximately 0.108% median in another settled renderer capture.
- Approximately 0.226% in an earlier settled diagnostic before the corrected lower readings.

CPU was therefore not the limiting metric by the end of the study. Further idle CPU tuning was frozen unless a later feature caused a regression.

## Media transition

The valid functional media gate was not achieved, so this transition was not accepted as an optimization result. The diagnostic-only static-to-media transition recorded approximately:

- +89.62 MiB complete-tree private resident memory.
- +65.31 MiB renderer private resident memory.
- +24.04 MiB GPU private resident memory.

The largest tracked allocation family changed from about 25.58 MiB to 70.62 MiB and later measured about 9.70 MiB. Because the functional and media-quality gates failed, this evidence does not establish waste or a production optimization opportunity.

## Allocation and profiling findings

- Chromium PartitionAlloc and V8/JIT were confirmed as allocation owners in limited virtual-allocation traces.
- Short steady-state VirtualAllocation traces could not account for memory allocated before tracing began.
- A PID-scoped elevated WPR HeapSnapshot completed with 268,651 events and zero lost events, but did not provide enough retained-allocation ownership to justify changing renderer behavior.
- The large anonymous allocation families remained hypotheses rather than proven cache, Blink, compositor, or media owners.
- No forced working-set trimming, repeated garbage collection, disabled media, disabled hardware acceleration, protocol change, security bypass, or unauthorized-access feature was accepted as an optimization.

## Final conclusion

Track B proved that a native Windows/WebView2 shell can reduce some desktop-container overhead, while Discord's initialized frontend remains the dominant memory cost. The approximately 250 MiB complete-tree idle target and approximately 0.2% median CPU target remained the design targets, but the memory target was not achieved without compromising normal functionality or changing Discord's frontend behavior. The project stops at the research boundary rather than claiming a finished optimized client.
