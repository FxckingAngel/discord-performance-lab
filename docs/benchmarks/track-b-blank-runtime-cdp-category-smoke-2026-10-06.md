# Track B blank-runtime CDP category smoke test

Date: 2026-10-06

This was a diagnostic-only `about:blank` WebView2 session in the isolated runtime-baseline profile. It did not load Discord or account data and is not a Track B performance result.

## Result

| Measurement | Value |
| --- | ---: |
| Total working set median | 366.83 MiB |
| Private working set median | 72.74 MiB |
| Private bytes median | 146.34 MiB |
| Display | 1920x1080 at 60 Hz |
| DOM documents / nodes / listeners | 2 / 8 / 0 |
| Image / video / canvas elements | 0 / 0 / 0 |
| All-time native category observed | V8, 1 MiB sampled |
| Window native allocation categories | No samples in the short window |

The result validates that the CDP diagnostic can return aggregate DOM data and categorized native samples without writing page content or raw profile data. The absence of samples in the short window is expected for a smoke run and does not show that the runtime has no native allocation activity.

The normal shell was left running and responsive after the blank diagnostic closed. Raw files remain local under `artifacts/`.
