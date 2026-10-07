# Track B blank versus Discord-loaded resident page types

Date: 2026-10-06

## Scope

This is a matched diagnostic pair using the same runner, 30-second settle, 20-second process/CDP window, and per-PID resident-page classification. The blank run used `--diagnostic-blank`; the loaded run used `--diagnostic-authenticated-no-bridges`. The route and workload were not independently verified, and the short windows are noisier than the long settled baseline. These are transition evidence, not acceptance measurements.

Sources:

- Blank manifest: `artifacts/track-b-blank-resident-types-20261006/resident-types.json`
- Loaded manifest: `artifacts/track-b-authenticated-resident-types-20261006/resident-types.json`
- Comparison: `artifacts/track-b-blank-vs-auth-resident-delta-20261006.json`

## Complete-tree delta

| Category | Blank | Discord-loaded | Delta |
|---|---:|---:|---:|
| Resident pages | 373.61 MiB | 871.48 MiB | +497.88 MiB |
| Private writable resident | 55.03 MiB | 419.94 MiB | +364.91 MiB |
| Private executable resident | 0.024 MiB | 0.039 MiB | +0.015 MiB |
| Private other protection | 1.43 MiB | 1.92 MiB | +0.50 MiB |
| Mapped resident | 29.94 MiB | 64.91 MiB | +34.97 MiB |
| Image-backed resident | 287.19 MiB | 384.67 MiB | +97.48 MiB |

The resident total is a sum of per-process readings and can count shared physical pages more than once. Private writable remains the useful diagnostic category, but it is still not a perfect unique-page measurement.

## Renderer delta

| Category | Blank renderer | Discord renderer | Delta |
|---|---:|---:|---:|
| Resident pages | 50.38 MiB | 432.05 MiB | +381.68 MiB |
| Private writable resident | 8.13 MiB | 321.60 MiB | +313.47 MiB |
| Private executable resident | 0.02 MiB | 0.02 MiB | 0 MiB |
| Mapped resident | 3.42 MiB | 30.03 MiB | +26.61 MiB |
| Image-backed resident | 38.54 MiB | 79.34 MiB | +40.80 MiB |

The role-level renderer delta is measured at the final resident-classification instant, while process-tree medians are measured over the preceding window. They must not be numerically substituted for each other.

## Interpretation

The paired result reinforces the current direction: loading Discord creates a large private-writable renderer category, while executable pages remain negligible. The blank runtime's image-backed floor is visible, but it is not large enough to explain the Discord-loaded renderer gap. The next feature transitions should reuse this exact manifest format for static text, media, voice, video, and screen sharing.
