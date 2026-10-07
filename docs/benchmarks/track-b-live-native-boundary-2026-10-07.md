# Track B live native memory boundary

Date: 2026-10-07

This is a 30-second read-only capture of the running Track B shell. The exact
Discord route and workload were not manually confirmed, so it is diagnostic
evidence only. Official Discord was not touched. Raw per-process and virtual
memory artifacts remain local under `artifacts/track-b-live-attribution-20261007-101040`.

## Process-tree boundary

| Metric | First sample | Last sample |
| --- | ---: | ---: |
| Process count | 8 | 8 |
| Total working set | 868.31 MiB | 810.80 MiB |
| Summed private working set | 462.85 MiB | 413.75 MiB |
| Private bytes | 673.90 MiB | 680.90 MiB |
| Total CPU sample | 0.424% | 0.126% |

The final sample preserved these individual roles: native shell, WebView2
browser, renderer, GPU process, Crashpad, network service, storage service,
and audio service. The renderer PID was 14708.

## Renderer boundary

| Category | MiB |
| --- | ---: |
| Resident pages | 377.73 |
| Unique private resident pages | 286.28 |
| Private-writable resident pages | 285.22 |
| Private-writable committed pages | 325.31 |
| Mapped resident pages | 18.85 |
| Image resident pages | 72.71 |
| Committed address space | 1,072.79 |

The Windows working-set classification reported approximately 300.17 MiB of
unique private resident pages for the renderer. The process-counter private
working-set value was approximately 299.09 MiB. These are close enough to
cross-check the renderer identity, but they remain separate measurements and
must not be summed together.

The renderer had 2,681 queried virtual-memory regions, including 2,135
private-writable regions. Only two private-writable regions were at least 16
MiB, and their combined resident contribution was approximately 18.75 MiB in
this capture. The bulk of the private-writable resident memory is therefore
distributed across smaller regions rather than one single giant resident
region.

## Interpretation

This capture does not identify an allocator or module owner. It does establish
that the current renderer's private resident footprint is real native/private
resident memory, not merely reserved address space, and that the mapped and
image portions are comparatively small. The next attribution step is a
same-renderer workload transition that correlates these boundaries with the
existing allocation-family identities and CDP media metrics.

No renderer flags, cache policy, media behavior, garbage collection, or
working-set trimming were changed.
