# Track B workload matrix

The idle floor is a separate gate. Real-use workloads must also be measured against pristine Official Discord on the same machine and state. Active-workload RAM limits remain unset until the corresponding official baselines exist. A lower number with a broken or visibly changed feature is a failed result.

## Common comparison contract

Run each row for Official Discord and Track B as separate captures. Do not restart or stop the user's active official instance. A pristine isolated official reference must be used for a comparison; measurements from the Vencord-patched installation are labelled `Official Discord + Vencord` and are descriptive only.

No workload may pass by disabling visible GIFs, stickers, media, voice, video, notifications, or screen sharing. Diagnostic static states are not production optimizations.

Action-qualified workload captures must record an operator-supplied functional status (`PASS`, `FAIL`, or `UNTESTED`) and the duration of the exercised action. The harness stores only that metadata; it does not collect account content. A workload is not a functional pass when the action was not exercised or the status remains `UNTESTED`.

For repeated active-use captures, use `tools/Invoke-TrackBActiveWorkloadCheckpoint.ps1`. It requires one `READY` confirmation per repetition and records a sanitized contract for the workload state. The contract does not replace the separate functional pass/fail checkpoint.
Before either capture, record a sanitized manifest with:

- `workload` and a stable `routeKey` with no account, server, channel, message, or URL data;
- provenance (`pristine-official-discord` or `track-b`), build/version, executable/package hash, and launch/profile class;
- the same account, exact route, call/media state, 1920x1080 display, 60 Hz refresh rate, window dimensions, scaling, power mode, network condition, and background applications;
- readiness time, settle condition, action start/end, measurement start/end, and root PID plus creation time;
- a manual checkpoint result proving the frontend is fully initialized and the route did not change during capture.

Every run must retain, or link to, these evidence groups:

| Evidence | Required fields | Existing source |
| --- | --- | --- |
| Complete process tree | total working set, private working set, derived/shareable working set, private bytes/commit, CPU samples, process count, per-PID role, handles, threads, creation time | `Measure-DiscordProcessTree.ps1` or `Invoke-TrackBFeatureScenarioCheckpoint.ps1` |
| Active attribution | per-PID CPU median/p95, page faults, private/total/shareable memory, window state, display refresh rate, renderer identity | `Measure-DiscordPhase2Attribution.ps1` and `Summarize-DiscordPhase2Attribution.ps1` |
| GPU | GPU engine/activity and GPU memory for media, video, and screen sharing; explicit `not-applicable` for workloads with no GPU-specific measurement | local GPU/trace artifact, never inferred from renderer memory |
| Responsiveness | readiness, action latency or frame/interaction observation, unresponsive flag, and any missed/deferred interaction | sanitized manual or automated responsiveness record |
| Functionality | scenario-specific PASS/FAIL/UNTESTED with a short sanitized note | `Invoke-TrackBFunctionalCheckpoint.ps1` or an attached scenario checklist |

The comparison is incomplete if a required field is absent. `not-applicable` is allowed only for GPU fields on workloads that do not exercise GPU-dependent behavior. It is not a substitute for missing memory, CPU, responsiveness, or functional evidence. Report median and p95 for samples, not only the last sample. Preserve per-PID rows before aggregating the tree.

For every numeric resource metric report Official Discord, Track B, absolute delta, and percentage improvement using:

`(official - trackB) / official * 100`

For responsiveness and functionality, report the two results directly. Do not convert a functional failure into a resource improvement.

## Capture recipe

Use three repetitions per workload as the minimum. Use five when the private-working-set range or CPU p95 exceeds the expected improvement. Each repetition has four explicit phases:

1. **Prepare:** manually establish the exact route and workload state. Do not enter credentials or account data into a script.
2. **Settle:** wait for the workload-specific condition below, then confirm that the root PID, renderer PID, process count, route, and window state are stable.
3. **Exercise:** perform only the listed fixed actions. Record the action interval separately from the settled interval.
4. **Recover/settle:** stop the action without disabling the feature, wait for the post-action settle condition, and record whether memory and responsiveness recover.

Use `Invoke-TrackBFeatureScenarioCheckpoint.ps1` for Track B scenario captures. It requires a literal `READY`, preserves the rooted process identity, and writes the process tree plus resident/virtual-memory evidence. Pair it with Phase 2 attribution when page faults, window/display state, or per-sample CPU p95 is required. No row below is considered captured until the manual checkpoint and all required evidence groups are attached.

## Matrix

| ID | Fully initialized state and fixed exercise | Settle / action / recovery | Protected behavior | Required GPU fields |
| --- | --- | --- | --- | --- |
| `settled-idle` | Exact static DM or text channel, untouched, no call, no typing, no scrolling | 60 s stable precondition / 10 min untouched / 60 s post-check | session, route, notifications, responsive UI | `not-applicable` unless GPU activity is being studied |
| `active-text` | Navigate to a fixed text route, type and send a sanitized test message if permitted, edit/react to it, open one image/embed | 60 s stable / 3 min fixed interaction sequence / 2 min settled | messaging, editing, reactions, images/embeds | GPU activity and memory if image/embed is visible |
| `channel-navigation` | Visit the same three preselected channels/DMs in the same order and pause on each | stable source route / 30 s per route, one sequence repeated three times / 2 min settled | navigation, route restoration, search if included | `not-applicable` unless media is visible |
| `scrolling` | Scroll the same channel/history range at a fixed cadence without changing route | 60 s stable / 5 min scrolling / 2 min settled | scroll smoothness, history loading, input responsiveness | GPU activity and memory when compositing is exercised |
| `media-heavy` | Same channel with visible GIFs, stickers, images, and embeds; leave visible media enabled | 60 s stable / 5 min visible media / 5 min after leaving the route, then return to the static route | visible animation/media, audio, navigation, reclamation after leaving | GPU engine/activity, GPU memory, decoded-media or raster evidence where available |
| `voice-idle` | Connected to the same voice call with microphone/output selected and nobody speaking | 60 s connected and stable / 5 min quiet call / 2 min after disconnect | voice connection, chat, device controls, notifications | GPU fields only if the client renders call video/media |
| `active-voice` | Same voice state with controlled incoming/outgoing speech and microphone processing | 60 s connected / 5 min speech interval / 2 min quiet recovery | audio quality, reconnects, chat, notifications, push-to-talk if tested | GPU fields only if exercised by the call UI |
| `video` | Same video call, camera and device controls enabled, with a fixed participant/layout state | 60 s stable video / 5 min video / 2 min after camera stop | camera, output selection, frame stability, latency, controls | GPU engine/activity, GPU memory, frame stability, encoder cost |
| `screen-sharing` | Share the same fixed window or display at the same quality and layout | 60 s sharing / 5 min share / 2 min after stopping | capture source, quality, controls, audio if enabled, recovery | GPU engine/activity, GPU memory, encoder cost, frame stability, latency |
| `notifications` | Leave the same route open, receive one controlled notification, open it, and return to the route | 60 s stable / receive-open-return sequence repeated three times / 2 min settled | notification delivery, open target, route restoration, no delayed UI | `not-applicable` unless notification opens media |
| `gaming-background` | Same game, account state, display, and network; Discord remains in the documented background state | 2 min game settled / 10 min background use / 2 min after returning Discord foreground | no notification delay, no call loss, no foreground recovery lag | GPU activity/memory for Discord and game must be separated if collected |

`settled-idle` is the only row judged against the approximately 250 MiB private-resident and 0.2% median CPU design target. Active rows are first compared against pristine Official Discord, then assigned targets from measured evidence. Video and screen sharing are not idle regressions; report their workload cost, frame stability, latency, and functional result separately.

## Per-row report shape

Each official/Track B pair should produce a sanitized record with this shape. Paths point to local evidence and must not contain account or message data.

```json
{
  "schemaVersion": 1,
  "workload": "media-heavy",
  "routeKey": "redacted-static-media-route",
  "official": {
    "provenance": "pristine-official-discord",
    "summaryPath": "official-summary.json",
    "functionalStatus": "PASS",
    "responsiveness": { "status": "PASS", "unresponsive": false },
    "gpu": { "status": "captured", "artifactPath": "official-gpu.json" }
  },
  "trackB": {
    "provenance": "track-b",
    "summaryPath": "track-b-summary.json",
    "functionalStatus": "PASS",
    "responsiveness": { "status": "PASS", "unresponsive": false },
    "gpu": { "status": "captured", "artifactPath": "track-b-gpu.json" }
  },
  "matchedState": {
    "windowWidth": 1264,
    "windowHeight": 768,
    "displayWidth": 1920,
    "displayHeight": 1080,
    "refreshHz": 60,
    "sameRoute": true,
    "sameWorkload": true,
    "fullyInitialized": true
  }
}
```

This is a contract example only. It is not evidence of a captured authenticated workload. Do not fill it with guessed values or claim `READY` on behalf of the user.

No workload may pass by disabling visible GIFs, stickers, media, voice, video, notifications, or screen sharing. Releasing resources that are no longer visible or needed is permitted only when the visible behavior and recovery path remain unchanged.
