# Track B Friends-route renderer attribution

Date: 2026-10-07  
Route: sanitized `discord-channels` on `https://discord.com`  
Mode: authenticated diagnostic profile with no partial native bridge  
Renderer PID: local diagnostic PID, retained only in ignored raw artifacts

## Renderer measurements

| Category | Observed result |
|---|---:|
| Renderer private working set during the paired scan | 336.99 MiB |
| Renderer private bytes | 384.89 MiB |
| V8 used heap | 125.73 MiB |
| V8 total heap | 246.67 MiB |
| V8 embedder heap used | 28.59 MiB |
| V8 backing storage | 28.61 MiB |
| Blink documents | 13 |
| DOM nodes | 5,878 |
| JavaScript event listeners | 2,248 |
| Layout objects | 3,516 |
| Image elements | 132 |
| Natural image pixels | 3,117,873 |
| Video elements | 3 |
| Playing videos | 0 |
| Canvas elements | 4 |
| Canvas pixels | 1,111,155 |

The values are aggregate diagnostics only. No page text, account data, tokens, raw URLs, heap objects, or snapshots were written.

## Windows virtual-memory classification

The read-only `VirtualQueryEx` scan of the same renderer reported:

| Classification | Committed bytes |
|---|---:|
| Private committed | 388.0 MiB |
| Private writable committed | 385.0 MiB |
| Private executable committed | 12.9 MiB |
| Private other protection | 2.3 MiB |
| Mapped committed | 396.2 MiB |
| Image committed | 369.8 MiB |
| Private writable regions | 2,186 |
| Private writable regions over 1 MiB | 49 |
| Largest private writable region | 34.0 MiB |

Committed virtual memory is not resident memory, and mapped/image totals are not unique physical RAM. These values are therefore classification evidence, not an additive RAM ledger.

## Interpretation

V8 used heap is approximately 126 MiB while renderer private working set is approximately 337 MiB. Even including V8 backing storage and embedder heap, a large portion of the resident renderer remains outside live JavaScript accounting. The current evidence does not identify that remainder as a cache, compositor, image decoder, or Blink allocation.

The CDP native sampling window collected only a small `msedge.dll` sample and cannot account for the full resident renderer. It must not be extrapolated to the full private working set.

The next optimization experiment should target one measured native owner from a lifecycle or feature differential. No GC change, working-set trim, media disablement, or Chromium flag change is justified by this capture alone.
