# Track B renderer memory classification, 2026-10-07

This read-only classification was taken from the live Verified shell after the
current process-tree baseline. It uses `VirtualQueryEx` and working-set page
classification. The renderer was PID 28160 at capture time. The complete-tree
virtual classification covered eight processes.

Source artifacts:

- `artifacts/track-b-renderer-memory-classification-20261007/resident-types.json`
- `artifacts/track-b-renderer-memory-classification-20261007/virtual-types.json`

## Renderer boundary

| Category | MiB |
| --- | ---: |
| Total resident working set | 390.32 |
| Private writable resident | 287.91 |
| Private executable resident | 0.02 |
| Other private resident | 1.06 |
| Mapped resident | 25.86 |
| Image-backed resident | 75.46 |
| Committed private writable | 331.69 |
| Committed private executable | 0.02 |
| Committed private other protection | 2.31 |
| Committed mapped | 368.30 |
| Committed image | 369.62 |
| Committed address space | 1,071.95 |
| Reserved address space | 3,701,897.29 |

The resident private-writable value is the important result. It is close to the
renderer private-working-set measurement from the paired process capture and
accounts for most of the renderer's private resident footprint. The committed
private-writable value is about 43.78 MiB above its resident value, so that
additional committed memory was not resident at this instant.

The very large reserved value is virtual address space, not RAM, and is not
counted toward the Track B memory target. Image-backed and mapped pages are
reported separately and are not silently added to private resident memory.

## Complete-tree context

The renderer was the only process with a large private writable resident
allocation. Its 287.91 MiB private writable resident and 331.69 MiB committed
private writable dominate the other roles. The GPU process had 83.14 MiB
committed private writable, while the browser had 38.14 MiB; those are
committed values and must not be treated as resident values without a matching
working-set capture.

This evidence narrows the next investigation to feature-dependent ownership of
the renderer's private writable pages. It does not prove that the pages are
V8, Blink, media, compositor, or removable. No renderer behavior was changed
and no security, authentication, or network behavior was modified.
