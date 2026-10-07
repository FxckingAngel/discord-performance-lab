# Track B reload and settled-state comparison

Date: 2026-10-07

This was a diagnostic-only authenticated no-bridge run with a renderer reload immediately before the 120-second capture. The route and workload were not independently verified.

## Results

The first five samples after reload were still in a transient loading state:

- Private working set: approximately 559.20 MiB median
- Private bytes: approximately 732.11 MiB median
- CPU: approximately 0.334% median

The final five samples after the extended observation settled near the prior loaded baseline:

- Private working set: approximately 420.31 MiB median
- Private bytes: approximately 595.27 MiB median
- CPU: approximately 0.117% median
- Renderer final private working set: 311.27 MiB

The prior loaded diagnostic measured 416.69 MiB private working set median and 303.74 MiB renderer private working set. The reload therefore did not materially reduce the steady renderer footprint.

The post-reload CDP snapshot reported 158.09 MiB V8 used heap, 7,212 DOM nodes, 15 documents, and 4,610 event listeners. These values differ from the earlier loaded snapshot, so the route/workload remains unverified and the counts are diagnostic only. No heap snapshot was retained or published.

## Interpretation

The memory gap is not explained by a one-time renderer cache that disappears after a reload. The steady renderer remains around 300 MiB private working set. The next meaningful comparison remains the manually confirmed static-channel versus media-heavy scenario matrix.

Raw data is in `artifacts/track-b-current-reload-long-cdp-native-20261007/`.
