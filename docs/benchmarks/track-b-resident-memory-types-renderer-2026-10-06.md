# Track B renderer resident-memory type classification

Date: 2026-10-06

## Scope

This is a read-only `VirtualQueryEx` plus `QueryWorkingSetEx` classification of renderer PID 16256. It was taken from the live normal shell and is an instantaneous diagnostic, not a settled acceptance benchmark. Per-process classifications are not cross-process physical-page deduplication.

Raw output: `artifacts/track-b-resident-memory-renderer-20261006.json`

## Result

| Category | Resident |
|---|---:|
| Total resident pages returned | 416.03 MiB |
| Private writable | 308.57 MiB |
| Private executable | 0.023 MiB |
| Private other protection | 1.06 MiB |
| Mapped | 30.23 MiB |
| Image-backed | 76.14 MiB |
| Process working set counter | 418.83 MiB |
| Process private bytes | 353.54 MiB |

## Interpretation

The renderer's resident pages are overwhelmingly private writable pages. Private executable pages are negligible, so reducing JIT or code memory cannot account for the required approximately 140 MiB reduction. Image-backed and mapped pages are also materially smaller than the writable private category.

The private writable category still combines V8 backing stores, Blink and DOM state, decoded resources, compositor buffers, allocator arenas, and other native data. The next optimization work must distinguish those writable categories without treating the whole category as disposable or using forced paging.

No application behavior, security setting, Discord protocol behavior, or production runtime setting was changed.
