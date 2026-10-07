# Track A pristine reference: read-only plan

Date: 2026-10-07

## Decision

No local installation currently qualifies as a pristine Official Discord reference. The active PTB installation is Vencord-patched, and the previously extracted stable package is incomplete for a runnable same-build desktop control because its required native module payload is absent.

The next safe step is to obtain a complete official package for one release channel, verify its provenance, and use a new installation/profile boundary. This report is planning evidence only. It does not launch an installer or Discord client.

## Read-only findings

The active local Discord installation is the PTB tree at:

`<local DiscordPTB installation>`

The Discord host executable is signed by Discord Inc. That signature does not prove that the client environment is unmodified. The installed `resources\app.asar` is a small loader whose embedded entry point requires the Vencord patcher at:

`<local Vencord installation>`

The active PTB process tree was present during inspection. It was not stopped, restarted, patched, or used as the diagnostic profile.

The separate local diagnostic area contains an extracted stable package labeled version `1.0.9260`. Its host executable is Discord-signed and its `resources\build_info.json` identifies the stable Windows x64 channel. Its frontend archive and bootstrap manifest are present, but the extracted package has no installed native module directory or bundled module ZIP payloads. Its bootstrap manifest requests seven native modules, including desktop core and voice. The earlier module-service attempt did not provide a usable module set for that old host version.

The extracted package therefore proves package identity and the absence of a Vencord loader in that extracted frontend archive, but it does not prove runnable completeness. It must not be benchmarked as pristine until its own native modules are present and match the host.

## Existing comparison boundary

The repository's official diagnostic launcher is appropriate for a known installed executable and a loopback read-only probe. It does not prove that the executable's frontend is unmodified, that native modules match the host, or that a profile is isolated. A separate profile and a `--vanilla`-style launch flag cannot undo a patcher embedded in the package.

The benchmark comparison tool requires an explicit `pristineOfficialReference` marker, `pristine-official-discord` provenance, and matching sanitized route, window, display, refresh-rate, and workload fields before it will treat an Official Discord capture as a valid A/B baseline. This gate is correct and must remain closed for the current PTB/Vencord installation and the incomplete extracted package.

## Safe isolated-reference procedure

1. Obtain a complete official package from Discord's distribution path for one selected channel. Prefer a package that includes its required native modules or whose own updater can populate them for the exact host version.
2. Place the package in a new directory outside `DiscordPTB`. Do not run the existing PTB setup or allow an installer to select the active PTB location.
3. Before execution, record the release channel, host version, architecture, package manifest, file hashes, and Authenticode status for signed PE files. Check that the host and every native module have matching versions and architecture.
4. Search the isolated package and launch configuration for Vencord, BetterDiscord, plugin, patcher, preload, or injected-client indicators. A signed host with a modified frontend is not a pristine reference.
5. Create a new profile directory. Do not copy cookies, tokens, Local Storage, IndexedDB, cache, or session files from any Discord installation.
6. Run a smoke launch only after the package gate passes. Confirm startup, the expected official process roles, the native module inventory, and a clean login page. Keep the first launch unauthenticated.
7. If an authenticated comparison is later authorized, log in manually in the isolated profile, establish the exact route and workload, and capture the same sanitized readiness manifest used for Track B.
8. Run at least three matched repetitions per workload before calculating improvement percentages. Keep raw process and profile artifacts private; publish only aggregate metrics and provenance fields.

The active PTB/Vencord instance remains outside this procedure. No files, modules, profile data, credentials, or frontend state may be copied from it.

## Fallback

If a same-build package cannot be obtained, use the newest complete clean package available for the same channel as a secondary control. Record the channel, version, module versions, package hashes, and profile class in every result. If the channel or build differs from Track B's reference, label the result as a version-mismatched secondary control and do not calculate an Electron/container tax from it.

Until either control is captured, existing measurements must remain labeled `Official Discord + Vencord`, `secondary official package/profile`, or `diagnostic-only`. None can close the pristine same-route A/B gate.

## Limitations

- The read-only inspection cannot prove that a newly downloaded package is clean without checking its complete file set and launch behavior.
- Authenticode validates signed PE publishers, not the contents of unsigned archives or the absence of runtime injection.
- A separate profile prevents session-data reuse but does not repair a modified executable or frontend.
- The current extracted stable package is not a viable performance reference until its required native modules are supplied by its own official distribution path.
- No account data, page content, credentials, tokens, or sensitive process command lines were read into this report.

## Result

The safe next action is provenance-checked acquisition of a complete isolated official package. The active Vencord Discord remains untouched, and Track B development can continue independently while the pristine reference gate is pending.
