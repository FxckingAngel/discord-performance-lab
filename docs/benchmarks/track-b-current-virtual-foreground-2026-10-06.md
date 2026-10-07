# Track B current foreground virtual-memory classification

This is a read-only `VirtualQueryEx` classification of the current foreground Release shell. It is paired with the recent foreground process-tree check but is not an authenticated route acceptance benchmark.

| Role | Private committed | Private writable committed | Private executable committed | Largest writable region | Writable regions |
| --- | ---: | ---: | ---: | ---: | ---: |
| Renderer | 346.2 MiB | 343.8 MiB | 11.2 MiB | 22.5 MiB | 2,239 |
| GPU process | 118.0 MiB | 117.6 MiB | 0.0 MiB | not recorded in summary | not recorded in summary |
| Browser | 36.8 MiB | 36.4 MiB | 0.0 MiB | not recorded in summary | not recorded in summary |

The renderer has 55 private writable regions larger than 1 MiB. Its committed private memory is still dominated by writable pages, while executable memory is a small category. The raw classification is `artifacts/track-b-current-virtual-foreground-20261006/virtual-types.json`.
