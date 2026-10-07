# Track B same-renderer native family tracking

Date: 2026-10-07

The three captures in the native-family lifecycle run used renderer PID 35976. Because the PID stayed constant, allocation-base values can be compared within this run. They must not be compared across separate processes because ASLR changes virtual addresses.

| Allocation base | Protection | Startup 5s | Frontend 15s | Friends 40s |
| --- | --- | ---: | ---: | ---: |
| `0x28900000000` | Private read/write | 210.29 MiB | 47.51 MiB | 247.54 MiB |
| `0x7D6C00000000` | Private read/write | 50.56 MiB | 25.80 MiB | 66.91 MiB |

At Friends 40 seconds, the first family consisted of 17 regions and the second of 3 regions. The renderer had 517.58 MiB private-writable resident memory in total, with 210.96 MiB concentrated in six regions at least 16 MiB each. The largest family is therefore a real private-writable resident allocation family that changes with lifecycle state, not merely a repeated shared-page count.

This evidence still does not identify whether the family belongs to Blink, Skia, compositor resources, application state, or another Chromium allocator. No renderer behavior was changed. The next experiment must hold the renderer and route constant while comparing static text against visible media, then track these same families before and after leaving the media route.
