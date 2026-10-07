# Decision 0022: do not select a media-only renderer fix yet

Date: 2026-10-07

## Evidence

The isolated unauthenticated Discord renderer measured approximately 221.43 MiB private working set, 218.46 MiB private-writable resident, 234.45 MiB committed private-writable memory, and 22.48 MiB V8 used heap. Its largest anonymous allocation-base groups were approximately 86.34 MiB, 31.04 MiB, and 16.45 MiB.

The authenticated normal-shell series measured approximately 295–298 MiB private-writable renderer resident without navigation or feature changes. Its largest groups also changed resident size while the workload remained untouched.

## Decision

Do not choose decoded-image, GIF, sticker, or media-cache release as the first renderer optimization. The no-media unauthenticated state already contains large private-writable native groups, and the current evidence does not show that media owns the majority of the renderer gap.

The next optimization candidate must come from a lifecycle or workload delta that proves a reclaimable owner. The current leading branches are:

1. Discord frontend/application state added between unauthenticated and authenticated initialization.
2. WebView2/Chromium native state whose resident pages vary without corresponding committed-memory release.
3. A retained document, frame, or renderer resource that appears only after the authenticated route is fully initialized.

No production renderer behavior, media behavior, security setting, or Chromium launch flag was changed from this decision.
