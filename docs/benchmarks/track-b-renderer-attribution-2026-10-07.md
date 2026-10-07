# Track B renderer attribution refresh

Date: 2026-10-07

This capture used the authenticated Track B diagnostic profile on the primary monitor after the Friends route checkpoint. It did not modify renderer behavior, Chromium flags, authentication, or Discord protocol behavior.

## Paired measurements

| Metric | Result |
| --- | ---: |
| CDP V8 used heap | 113.18 MiB |
| CDP V8 total heap | 112.87 MiB |
| DOM nodes | 5,904 |
| Documents / frames | 13 / 13 |
| JavaScript event listeners | 2,169 |
| Image elements / natural image pixels | 132 / 2,518,896 |
| Video elements / playing | 3 / 0 |
| Renderer private working set median | 353.58 MiB |
| Complete-tree private working set median | 461.53 MiB |
| Complete-tree private working set range | 452.26–481.91 MiB |
| Settled CPU median | 0.108% |

The renderer therefore retains roughly 240 MiB or more outside measured live V8 heap. The CDP native sampling window attributed only about 1.09 MiB to Chromium native allocations, so it is a sampling observation, not a complete accounting of resident memory.

## Windows resident-region classification

The renderer scan reported 368.43 MiB private-writable resident and 412.24 MiB committed private-writable memory. The largest allocation-base family contained 152.88 MB resident and 154.40 MB committed across ten regions. The five private-writable regions at least 16 MiB accounted for 113.86 MiB resident. These are process-local allocation families; their addresses are not stable identities across renderer lifetimes and do not establish whether the owner is Blink, Chromium, Discord state, media, or a runtime arena.

## Decision

No renderer behavior change is justified yet. The next experiment must track the largest region families through blank, authenticated static, and media states or join them to reliable allocation-stack evidence. CPU is already below the 0.2% median target in this capture; memory remains the primary optimization problem.

Raw CDP, process, virtual-memory, and resident-page artifacts remain private under `artifacts/track-b-renderer-attribution-20261007/`.
