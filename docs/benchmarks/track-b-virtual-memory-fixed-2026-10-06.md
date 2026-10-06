# Track B virtual-memory classification after collector fix

Date: 2026-10-06

## Scope

The existing read-only `VirtualQueryEx` collector initially returned no rows because its embedded C# used syntax unsupported by the available Windows compiler. The helper was updated to use compatible dictionary initialization and explicit `out` variables, then rerun against the live Track B root PID 38700. The collector now reports eight processes.

This is an instantaneous diagnostic. The route and workload were not independently verified, and it is not a settled acceptance benchmark.

Raw artifacts:

- `artifacts/track-b-virtual-memory-current-20261006.json`
- `artifacts/track-b-working-set-pages-current-20261006.json`

## Renderer classification

| Category | Renderer |
|---|---:|
| Private committed | 400.40 MiB |
| Private writable committed | 398.06 MiB |
| Private executable committed | 10.41 MiB |
| Mapped committed | 370.23 MiB |
| Image committed | 369.62 MiB |
| Private writable regions over 1 MiB | 46 |
| Resident working-set reading | 486.31 MiB |

The process was PID 16256 at the time of the read. The complete-tree working-set-page reading was 932.64 MiB across eight processes; this is a separate instantaneous read and is not a private-working-set total.

## Other private committed categories

| Role | Private committed |
|---|---:|
| GPU process | 117.94 MiB |
| Browser/utility | 41.32 MiB |
| Network service | 9.28 MiB |
| Native shell | 7.30 MiB |
| Storage service | 3.37 MiB |
| Crashpad | 1.31 MiB |

## Interpretation

The renderer's committed private memory is overwhelmingly writable rather than executable. This confirms that code/JIT pages are not the dominant committed-private category, but it still does not distinguish V8 backing stores, Blink structures, decoded media, compositor allocations, or native WebView2 buffers. The result is therefore a better attribution boundary, not a direct optimization target.

The collector now uses terminating error behavior so future embedded-compiler failures cannot silently produce an empty or zero-valued report.
