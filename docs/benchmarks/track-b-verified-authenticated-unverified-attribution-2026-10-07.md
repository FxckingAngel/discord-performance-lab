# Track B Verified authenticated diagnostic attribution

This was a 30-second read-only attribution run using the rebuilt Verified executable with the authenticated no-bridge diagnostic profile. It settled for 20 seconds first, then captured CDP and per-process counters. The route and workload were not manually verified, so this is not an acceptance benchmark.

Artifacts: `artifacts/track-b-verified-authenticated-unverified-20261007/`

## Settling behavior

The complete tree was still changing during the short capture:

| Window | Total working set | Private working set | Private bytes | Renderer private working set |
| --- | ---: | ---: | ---: | ---: |
| First sample | 1,025.73 MiB | 606.72 MiB | 791.57 MiB | 488.67 MiB |
| Last three median | 900.56 MiB | 471.27 MiB | 686.19 MiB | 349.92 MiB |

The GPU private working set was approximately 46.5 MiB in the last five samples. CDP reported 112.41 MiB V8 used heap, 6,241 DOM nodes, 2,242 listeners, 166 image elements, and 3 video elements. The native allocation sample window was only 1.11 MiB, so it does not account for the renderer resident total.

This run demonstrates why the authenticated diagnostic needs a longer settled period before comparison. The normal Verified shell was restored through its normal close path at the end of the run.
