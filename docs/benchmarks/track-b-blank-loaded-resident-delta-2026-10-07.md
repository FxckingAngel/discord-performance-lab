# Track B blank versus loaded resident delta

Date: 2026-10-07

This report uses the existing paired resident-type comparison between the
settled blank WebView2 shell and the settled authenticated Track B capture.
Source: `artifacts/track-b-blank-vs-authenticated-resident-types-20261007/comparison.json`.

## Aggregate delta

| Classification | Blank | Loaded | Delta |
| --- | ---: | ---: | ---: |
| Per-process resident total | 373.61 MiB | 870.03 MiB | +496.42 MiB |
| Private-writable resident | 55.03 MiB | 422.33 MiB | +367.29 MiB |
| Mapped resident | 29.94 MiB | 66.78 MiB | +36.84 MiB |
| Image resident | 287.19 MiB | 379.02 MiB | +91.82 MiB |

The resident total is a sum of per-process classifications and can count
shared physical pages more than once. Private-writable resident is the more
useful ownership signal here, but it is still not cross-process unique-page
accounting.

## Private-writable delta by role

| Role | Delta |
| --- | ---: |
| Renderer | +318.53 MiB |
| GPU process | +32.43 MiB |
| Browser | +10.43 MiB |
| Network service | +3.83 MiB |
| Audio service | +1.60 MiB |
| Storage service | +0.47 MiB |
| Native shell | +0.13 MiB |
| Crashpad | -0.12 MiB |

The renderer is therefore the first optimization target by a wide margin,
followed by GPU/compositor-related allocations. The result does not prove that
all renderer pages are Discord-owned or reclaimable. It does establish that
generic shell/runtime floor work cannot explain the loaded-state gap by
itself.

## Limits

The blank and loaded captures were separate process trees, so role matching is
by recorded role rather than stable PID. The comparison is not a same-process
before/after experiment, does not deduplicate physical pages across
processes, and does not identify JavaScript versus Blink/native ownership.
Those categories still require paired CDP and native-memory diagnostics.
