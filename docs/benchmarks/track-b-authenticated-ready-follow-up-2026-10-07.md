# Track B authenticated-ready follow-up

Date: 2026-10-07

Artifacts:

- `artifacts/track-b-authenticated-follow-up-20261007.json`
- `artifacts/track-b-authenticated-follow-up-tree-20261007.json`
- `artifacts/track-b-authenticated-follow-up-renderer-types-20261007.json`

Track B was run alone with its diagnostic profile after the normal shell was stopped. The CDP readiness check passed on an authenticated Discord route:

- route class: `discord-channels`
- route: sanitized as Discord channels
- document ready: true
- `#app-mount` present with 6 children
- mount rectangle: 1280 x 768
- DOM readiness predicate: true
- no contract errors

The ten-second aggregate CDP diagnostic also collected a local-only heap-sampling result. It retained no message content, account values, tokens, or private URLs. The sample contained 18 samples and 594,556 sampled bytes. The result is not a full V8 heap size and is not used as a renderer-memory substitute.

The paired process-tree capture remained at eight processes. By the final sample:

| Metric | Complete tree | Renderer |
| --- | ---: | ---: |
| Private working set | 419.2 MiB | 312.8 MiB |
| Total working set | 831.3 MiB | 425.0 MiB |
| Private bytes | 544.7 MiB | 351.2 MiB |

The renderer resident classifier reported 302.3 MiB private-writable resident, 303.3 MiB total private resident, and 303.3 MiB process-local unique-private resident. Major private-writable allocation families were approximately 73.3 MiB, 40.7 MiB, and 19.1 MiB resident.

The same CDP capture reported:

- V8 used heap: 112.6 MiB
- V8 total heap: 222.1 MiB
- V8 backing storage: 23.8 MiB
- DOM nodes: 4,600
- frames: 2
- image elements: 138
- video elements: 3, none playing
- canvas elements: 4

The CDP native-sampling field is explicitly treated as insufficient for ownership attribution in this run: it contained one sample, no module mappings, and stack depth 1. Its 232.9 MiB sample matched the reported V8 total, so it is not evidence of native Chromium ownership.

The diagnostic tool now records a sanitized `SystemInfo.getProcessInfo` inventory from the browser CDP target. It retains only process type, numeric IDs, and CPU time, then marks whether exactly one renderer PID is available as the CDP renderer candidate. It does not record command lines, URLs, account data, or heap objects.

Using the same-state measurements, approximately 190.7 MiB of renderer private resident memory was outside the reported V8 used heap. That remainder is not assigned to a specific native subsystem yet; it remains the target for further lifecycle and allocation ownership work.

This is the first current result that satisfies the readiness gate while still showing a large memory gap to the 250 MiB target. It is therefore valid optimization evidence, not a performance win. No renderer behavior, media quality, or Discord functionality was disabled.
