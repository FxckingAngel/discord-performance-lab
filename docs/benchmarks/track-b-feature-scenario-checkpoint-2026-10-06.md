# Track B feature-scenario checkpoint

`tools/Invoke-TrackBFeatureScenarioCheckpoint.ps1` is the manual-state measurement path for the native-memory decomposition.

The user prepares one state, types `READY`, and the tool records a complete Track B process-tree time series for that state. It then runs the read-only `VirtualQueryEx` plus `QueryWorkingSetEx` classifier once per PID from the final sample. Renderer PIDs remain separate in both the process-tree capture and the resident manifest.

Supported scenario labels are:

- `blank-webview2`
- `discord-app-shell`
- `static-dm`
- `static-server-text`
- `media-heavy`
- `voice-idle`
- `active-voice`
- `video`
- `screen-sharing`

Example:

```powershell
.\tools\Invoke-TrackBFeatureScenarioCheckpoint.ps1 -Scenario static-server-text -DurationSeconds 600 -IntervalSeconds 10
```

For an acceptance-quality run, add `-RequireSettled`. This requires six consecutive five-second probes with the same complete process tree and window state, and limits renderer/GPU private-working-set variation to 1% before the measurement window begins.

```powershell
.\tools\Invoke-TrackBFeatureScenarioCheckpoint.ps1 -Scenario static-server-text -RequireSettled -DurationSeconds 600 -IntervalSeconds 10
```

The output keeps total working set, private working set, derived shareable working set, private bytes, CPU, handles, threads, and per-PID roles in `process-tree.json`. `resident-types.json` points to one local classification file per PID, and `virtual-types.json` records the complete tree's committed-region classification. The resident classifier reports both committed virtual regions and resident committed pages, separating `MEM_PRIVATE`, `MEM_MAPPED`, and `MEM_IMAGE` pages and further separating private writable, executable, and other pages. It also reports Windows shared-flag resident bytes within each private protection category. Reserved address space is reported separately and is not counted as RAM. The classifiers do not deduplicate shared physical pages between processes.

This checkpoint does not automate authentication, navigation, calls, screen sharing, or messages. It is diagnostic evidence only and is not an acceptance result until the same route and workload are confirmed for the official-versus-Track-B comparison.

Diagnostic launches also write a local `webview-process-info.json` snapshot using WebView2's supported `CoreWebView2Environment.GetProcessInfos` API. It records only process IDs and WebView2 process kinds. The API is documented by [Microsoft's WebView2 reference](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2environment.getprocessinfos).

After two or more scenarios are captured, use `tools/Summarize-TrackBFeatureScenarioCaptures.ps1` to produce one sanitized report with scenario totals, per-PID rows, and category deltas from a selected baseline:

```powershell
.\tools\Summarize-TrackBFeatureScenarioCaptures.ps1 `
  -InputDirectory .\artifacts\track-b-feature-static-server-text-...,.\artifacts\track-b-feature-media-heavy-... `
  -BaselineScenario static-server-text `
  -OutputPath .\artifacts\track-b-feature-comparison.json
```
