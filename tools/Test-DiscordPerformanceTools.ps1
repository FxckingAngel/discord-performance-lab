[CmdletBinding()]
param(
    [string] $ToolsPath
)

if ([string]::IsNullOrWhiteSpace($ToolsPath)) {
    $ToolsPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'tools'
}

$resolvedToolsPath = (Resolve-Path -LiteralPath $ToolsPath -ErrorAction Stop).Path
$scripts = @(Get-ChildItem -LiteralPath $resolvedToolsPath -Filter '*.ps1' -File | Where-Object Name -ne (Split-Path -Leaf $PSCommandPath))
if ($scripts.Count -eq 0) {
    throw "No PowerShell tools found in $resolvedToolsPath."
}

$failures = @()
foreach ($script in $scripts) {
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $script.FullName,
        [ref]$null,
        [ref]$parseErrors
    ) | Out-Null
    if ($parseErrors.Count -gt 0) {
        $messages = $parseErrors | ForEach-Object { $_.Message }
        $failures += "${($script.Name)}: $($messages -join '; ')"
    }
}

if ($failures.Count -gt 0) {
    throw ($failures -join [Environment]::NewLine)
}

$summaryTool = Join-Path $resolvedToolsPath 'Summarize-DiscordBenchmark.ps1'
$phase2SummaryTool = Join-Path $resolvedToolsPath 'Summarize-DiscordPhase2Attribution.ps1'
$compareTool = Join-Path $resolvedToolsPath 'Compare-DiscordBenchmark.ps1'
$measureTool = Join-Path $resolvedToolsPath 'Measure-DiscordProcessTree.ps1'
$joinTool = Join-Path $resolvedToolsPath 'Join-TrackBCdpWindowsAttribution.ps1'
$traceCompareTool = Join-Path $resolvedToolsPath 'Compare-TrackBCdpTrace.ps1'
$functionalCheckpointTool = Join-Path $resolvedToolsPath 'Invoke-TrackBFunctionalCheckpoint.ps1'
$visualCheckpointTool = Join-Path $resolvedToolsPath 'Invoke-TrackBVisualCheckpoint.ps1'
$acceptanceGateTool = Join-Path $resolvedToolsPath 'Test-TrackBAcceptance.ps1'
$memoryCheckpointTool = Join-Path $resolvedToolsPath 'Invoke-TrackBMemoryAttributionCheckpoint.ps1'
$rendererLedgerTool = Join-Path $resolvedToolsPath 'Summarize-TrackBRendererMemoryLedger.ps1'
$cdpTestTool = Join-Path $resolvedToolsPath 'Test-DiscordPhase2Cdp.ps1'
$featureProbeTool = Join-Path $resolvedToolsPath 'Probe-DiscordFeatureSupport.mjs'
$screenshotCompareTool = Join-Path $resolvedToolsPath 'Compare-DiscordScreenshots.py'
$smokeTool = Join-Path $resolvedToolsPath 'Test-TrackBShellSmoke.ps1'
$lifecycleTool = Join-Path $resolvedToolsPath 'Invoke-TrackBLifecycleAttribution.ps1'
$shellSourcePath = Join-Path (Split-Path -Parent $resolvedToolsPath) 'track-b/discord-shell/MainForm.cs'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('discord-performance-lab-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
    $functionalCheckpointSource = Get-Content -LiteralPath $functionalCheckpointTool -Raw
    if ($functionalCheckpointSource -notmatch 'Get-Process -Name .*\$ProcessName') {
        throw 'Functional checkpoint does not validate the Track B process before manual results are recorded.'
    }
    if ($functionalCheckpointSource -notmatch 'Responding') {
        throw 'Functional checkpoint does not validate shell responsiveness before manual results are recorded.'
    }
    if ($functionalCheckpointSource -notmatch 'rootPid') {
        throw 'Functional checkpoint does not retain the measured root PID.'
    }
    $visualCheckpointSource = Get-Content -LiteralPath $visualCheckpointTool -Raw
    if ($visualCheckpointSource -notmatch 'visualReviewPassed') {
        throw 'Visual checkpoint does not retain an explicit visual review result.'
    }
    $screenshotCompareSource = Get-Content -LiteralPath $screenshotCompareTool -Raw
    foreach ($requiredField in @('identical dimensions', 'differingPixelPercent')) {
        if ($screenshotCompareSource -notmatch [regex]::Escape($requiredField)) {
            throw "Screenshot comparator does not preserve $requiredField."
        }
    }
    if (-not (Test-Path -LiteralPath $acceptanceGateTool -PathType Leaf)) {
        throw 'Track B acceptance gate tool is missing.'
    }
    if (-not (Test-Path -LiteralPath $rendererLedgerTool -PathType Leaf)) {
        throw 'Renderer memory ledger tool is missing.'
    }
    $smokeSource = Get-Content -LiteralPath $smokeTool -Raw
    foreach ($requiredField in @('$shutdownDeadline = [DateTime]::UtcNow.AddSeconds(30)', 'Start-Sleep -Milliseconds 250')) {
        if ($smokeSource -notmatch [regex]::Escape($requiredField)) {
            throw "Shell smoke test does not allow bounded helper shutdown time: $requiredField"
        }
    }
    $lifecycleSource = Get-Content -LiteralPath $lifecycleTool -Raw
    foreach ($requiredField in @('[switch] $Automatic', "mode = if (`$Automatic) { 'automatic-unverified' } else { 'manual-checkpoint' }", 'Capture-Checkpoint $checkpoint.label $checkpoint.instruction -SkipReady', 'Automatic unverified')) {
        if ($lifecycleSource -notmatch [regex]::Escape($requiredField)) {
            throw "Lifecycle attribution does not preserve automatic unverified checkpoints: $requiredField"
        }
    }
    $lifecycleSummarySource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Summarize-TrackBLifecycleAttribution.ps1') -Raw
    foreach ($requiredField in @("[string]`$manifest.mode -eq 'automatic-unverified'", 'Automatic timed checkpoints are unverified')) {
        if ($lifecycleSummarySource -notmatch [regex]::Escape($requiredField)) {
            throw "Lifecycle summary does not preserve automatic-mode limitations: $requiredField"
        }
    }
    $cdpTestSource = Get-Content -LiteralPath $cdpTestTool -Raw
    foreach ($requiredField in @('[string]::IsNullOrWhiteSpace($OutputPath)', 'phase2-cdp-test-')) {
        if ($cdpTestSource -notmatch [regex]::Escape($requiredField)) {
            throw "CDP diagnostic probe does not provide a default output path: $requiredField"
        }
    }
    $ledgerResidentPath = Join-Path $tempRoot 'ledger-resident.json'
    $ledgerVirtualPath = Join-Path $tempRoot 'ledger-virtual.json'
    $ledgerOutputPath = Join-Path $tempRoot 'ledger-output.json'
    [pscustomobject]@{
        processId = 101
        memory = [pscustomobject]@{
            residentValidBytes = 300MB
            privateWritableResidentBytes = 200MB
            privateExecutableResidentBytes = 1MB
            privateOtherResidentBytes = 2MB
            mappedResidentBytes = 40MB
            imageResidentBytes = 57MB
            committedBytes = 500MB
        }
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ledgerResidentPath -Encoding utf8
    [pscustomobject]@{
        processes = @([pscustomobject]@{
            pid = 101
            role = 'renderer'
            privateWritableCommittedBytes = 250MB
            privateExecutableCommittedBytes = 2MB
            privateOtherProtectionCommittedBytes = 3MB
            mappedCommittedBytes = 100MB
            imageCommittedBytes = 145MB
        })
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ledgerVirtualPath -Encoding utf8
    & (Get-Command pwsh.exe).Source -NoProfile -File $rendererLedgerTool -ResidentTypesPath $ledgerResidentPath -VirtualTypesPath $ledgerVirtualPath -OutputPath $ledgerOutputPath | Out-Null
    $ledgerResult = Get-Content -Raw -LiteralPath $ledgerOutputPath | ConvertFrom-Json
    if ($ledgerResult.resident.privateWritableMiB -ne 200 -or $ledgerResult.committed.privateWritableMiB -ne 250 -or $ledgerResult.boundaries.privateWritableCommittedBeyondResidentMiB -ne 50) {
        throw 'Renderer memory ledger did not preserve nested resident fields or committed-minus-resident boundary.'
    }
    $memoryCheckpointSource = Get-Content -LiteralPath $memoryCheckpointTool -Raw
    foreach ($requiredField in @('READY', 'Measure-DiscordPhase2Attribution.ps1', 'Invoke-DiscordPhase2CdpDiagnostics.mjs', 'diagnostic-authenticated-no-bridges')) {
        if ($memoryCheckpointSource -notmatch [regex]::Escape($requiredField)) {
            throw "Memory attribution checkpoint does not contain $requiredField."
        }
    }
    $featureProbeSource = Get-Content -LiteralPath $featureProbeTool -Raw
    if ($featureProbeSource -notmatch 'registryAvailable' -or $featureProbeSource -notmatch 'registry-unavailable') {
        throw 'Feature-support probe does not distinguish an unavailable registry from a reported capability.'
    }
    $acceptanceGateSource = Get-Content -LiteralPath $acceptanceGateTool -Raw
    foreach ($requiredField in @('workingSetMiB', 'privateWorkingSetMiB', 'privateMemoryMiB', 'processCount', 'cpuPercentOfTotal', 'candidateBuildValid', 'functionalProcessValid', 'functionalCoverageComplete', 'functionalPassed', 'visualPassed', 'visualComparisonValid', 'measurementEvidence')) {
        if ($acceptanceGateSource -notmatch [regex]::Escape($requiredField)) {
            throw "Track B acceptance gate does not evaluate $requiredField."
        }
    }
    foreach ($functionalId in @('login-session', 'servers-channels', 'messaging', 'images-media', 'notifications', 'voice', 'video', 'screen-share', 'file-dialogs', 'clipboard-drag-drop', 'window-shell', 'accessibility')) {
        if ($functionalCheckpointSource -notmatch [regex]::Escape($functionalId) -or $acceptanceGateSource -notmatch [regex]::Escape($functionalId)) {
            throw "Functional checklist ID is not synchronized between the checkpoint and acceptance gate: $functionalId"
        }
    }
    $shellSource = Get-Content -LiteralPath $shellSourcePath -Raw
    if ($shellSource -notmatch 'var enableWindowBridge = diagnosticWindowBridge') {
        throw 'Normal shell bridge gating is not explicit.'
    }
    if ($shellSource -notmatch 'var enableHardwareBridge = diagnosticHardwareBridge') {
        throw 'Normal shell hardware bridge gating is not explicit.'
    }
    if ($shellSource -notmatch 'partial DiscordNative object') {
        throw 'Normal shell bridge gating does not document the blank-window regression.'
    }
    if ($shellSource -notmatch 'DesktopIdentityUserAgent' -or $shellSource -notmatch 'Settings\.UserAgent = DesktopIdentityUserAgent') {
        throw 'Normal shell does not apply the audited Discord Desktop identity signal.'
    }
    if ($shellSource -match 'if \(diagnosticUserAgent\)\s*\{\s*webView\.CoreWebView2\.Settings\.UserAgent') {
        throw 'Desktop identity is still limited to the diagnostic UA mode.'
    }
    $phase2Source = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Measure-DiscordPhase2Attribution.ps1') -Raw
    if ($phase2Source -match 'Get-CimInstance Win32_Process -Filter "Name=\$ProcessName\.exe"') {
        throw 'Phase 2 attribution must enumerate all processes before walking the rooted tree.'
    }
    foreach ($treeTool in @('Measure-DiscordProcessTree.ps1', 'Measure-DiscordPhase2Attribution.ps1', 'Measure-TrackBVirtualMemoryTypes.ps1', 'Measure-DiscordWorkingSetPages.ps1')) {
        $treeSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath $treeTool) -Raw
        if ($treeSource -notmatch 'ManagementDateTimeConverter') {
            throw "$treeTool does not guard PID reuse with process creation times."
        }
    }
    if ($phase2Source -notmatch "return 'native-shell'") {
        throw 'Phase 2 attribution does not preserve the native shell as a separate role.'
    }
    foreach ($requiredField in @('privateWorkingSetMiB', 'workingSetShareableMiB')) {
        if ($phase2Source -notmatch [regex]::Escape($requiredField)) {
            throw "Phase 2 attribution does not preserve per-PID $requiredField."
        }
    }
    foreach ($requiredField in @('IsIconic', 'CurrentRefreshRate', 'windowState', 'displayRefreshRate')) {
        if ($phase2Source -notmatch [regex]::Escape($requiredField)) {
            throw "Phase 2 attribution does not preserve $requiredField."
        }
    }
    if ($phase2Source -match '\$pid\s*=') {
        throw 'Phase 2 attribution must not assign to PowerShell''s read-only PID variable.'
    }
    $phase2SummarySource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Summarize-DiscordPhase2Attribution.ps1') -Raw
    foreach ($requiredField in @('privateWorkingSetMedianMiB', 'workingSetShareableMedianMiB', 'displayRefreshRate', 'windowStates')) {
        if ($phase2SummarySource -notmatch [regex]::Escape($requiredField)) {
            throw "Phase 2 summary does not report $requiredField."
        }
    }
    if ($phase2SummarySource -notmatch 'processTree') {
        throw 'Phase 2 summary does not retain complete process-tree totals.'
    }
    $bucketSummarySource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Summarize-DiscordPhase21MemoryBuckets.ps1') -Raw
    foreach ($requiredField in @('privateWorkingSetMedianMiB', 'Renderer private working set', 'Renderer private bytes', 'nativeAllocationCategories', 'domCounters', 'rendererAttribution', 'rendererCount', 'attributionCategories', 'blink-dom-layout', 'image-gif-media', 'chromium-native', 'gpu-shared-textures', 'webrtc-audio-video')) {
        if ($bucketSummarySource -notmatch [regex]::Escape($requiredField)) {
            throw "Phase 2 bucket summary does not preserve $requiredField."
        }
    }
    $cdpDiagnosticsSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-DiscordPhase2CdpDiagnostics.mjs') -Raw
    foreach ($requiredField in @('imageNaturalPixelCount', 'animatedImageHintCount', 'playingVideoCount', 'videoReadyStateCounts', 'videoPixelCount', 'canvasPixelCount', 'nativeAllocationCategories', 'domCounters', 'sampleStatus', 'available', 'reloadBeforeSampling', 'Page.reload')) {
        if ($cdpDiagnosticsSource -notmatch [regex]::Escape($requiredField)) {
            throw "CDP diagnostics do not report $requiredField."
        }
    }
    $traceSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Capture-TrackBCdpTrace.mjs') -Raw
    if ($traceSource -notmatch 'eventRatesPerSecond') {
        throw 'CDP trace does not normalize selected activity counts per second.'
    }
    foreach ($requiredField in @('redacted-url-or-path', 'No page text, URLs, cookies, tokens, heap objects')) {
        if ($cdpDiagnosticsSource -notmatch [regex]::Escape($requiredField)) {
            throw "CDP diagnostics do not enforce $requiredField."
        }
    }
    $traceWrapperSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBUnverifiedCdpTrace.ps1') -Raw
    foreach ($requiredField in @('expectedCdpPort', 'diagnostic-blank', '9223', '9230')) {
        if ($traceWrapperSource -notmatch [regex]::Escape($requiredField)) {
            throw "CDP trace wrapper does not preserve $requiredField."
        }
    }
    $minimizedCheckpointSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBMinimizedCheckpoint.ps1') -Raw
    if ($minimizedCheckpointSource -notmatch 'if \(-not \$\?\)') {
        throw 'Minimized checkpoint does not use the measurement command success status.'
    }
    $featureCheckpointSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBFeatureScenarioCheckpoint.ps1') -Raw
    if (([regex]::Matches($featureCheckpointSource, 'if \(-not \$\?\)').Count) -lt 2) {
        throw 'Feature scenario checkpoint does not use success status for its child tools.'
    }
    foreach ($requiredField in @('$settledDirectory', "'measurement.json'", "'process-tree.json'", 'Copy-Item -LiteralPath $treePath')) {
        if ($featureCheckpointSource -notmatch [regex]::Escape($requiredField)) {
            throw "Feature scenario checkpoint does not preserve the settled output contract: $requiredField"
        }
    }
    foreach ($scenarioName in @('active-text', 'channel-navigation', 'scrolling', 'media-heavy', 'voice-idle', 'active-voice', 'video', 'screen-sharing', 'notifications', 'gaming-background')) {
        if ($featureCheckpointSource -notmatch [regex]::Escape($scenarioName)) {
            throw "Feature scenario checkpoint does not expose the workload scenario: $scenarioName"
        }
    }
    $phase21ScenarioSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-DiscordPhase21Scenario.ps1') -Raw
    foreach ($requiredField in @('RequireReadyEachRepetition', 'Prepare $Scenario repetition', 'Manual checkpoint was not confirmed', 'requireReadyEachRepetition')) {
        if ($phase21ScenarioSource -notmatch [regex]::Escape($requiredField)) {
            throw "Phase 2.1 scenario runner does not preserve $requiredField."
        }
    }
    $synchronizedAttributionSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBUnverifiedCurrentAttribution.ps1') -Raw
    foreach ($requiredField in @('webview-process-info*.json', '$inventoryOverlap', '$treePids', 'processId')) {
        if ($synchronizedAttributionSource -notmatch [regex]::Escape($requiredField)) {
            throw "Synchronized attribution does not select a matching WebView2 inventory: $requiredField"
        }
    }
    $residentTypesSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Measure-TrackBResidentMemoryTypes.ps1') -Raw
    foreach ($requiredField in @('RegionBucket', 'privateWritableRegionCount', 'privateWritable16MiBOrLargerResidentBytes', 'privateWritableResidentBucketsMiB', 'GetLargestPrivateWritableRegions', 'largestPrivateWritableRegions', 'allocationBaseGroups', 'allocationBase', 'residentBytes', 'protect')) {
        if ($residentTypesSource -notmatch [regex]::Escape($requiredField)) {
            throw "Resident memory classifier does not preserve $requiredField."
        }
    }
    $regionCorrelationTool = Join-Path $resolvedToolsPath 'Correlate-TrackBResidentRegions.ps1'
    if (-not (Test-Path -LiteralPath $regionCorrelationTool -PathType Leaf)) {
        throw 'Resident-region module correlation tool is missing.'
    }
    $regionCorrelationSource = Get-Content -LiteralPath $regionCorrelationTool -Raw
    foreach ($requiredField in @('largestPrivateWritableRegions', 'Get-Process.Modules', 'moduleMatchedRegionCount')) {
        if ($regionCorrelationSource -notmatch [regex]::Escape($requiredField)) {
            throw "Resident-region module correlation does not preserve $requiredField."
        }
    }
    $rendererLedgerJoinTool = Join-Path $resolvedToolsPath 'Summarize-TrackBRendererAttributionLedger.ps1'
    if (-not (Test-Path -LiteralPath $rendererLedgerJoinTool -PathType Leaf)) {
        throw 'Renderer attribution ledger join tool is missing.'
    }
    $rendererLedgerJoinSource = Get-Content -LiteralPath $rendererLedgerJoinTool -Raw
    foreach ($requiredField in @('privateWritableResidentMinusV8UsedMiB', 'nativeSampledMiB', 'backingStorageMiB', 'Sanitized aggregate join')) {
        if ($rendererLedgerJoinSource -notmatch [regex]::Escape($requiredField)) {
            throw "Renderer attribution ledger does not preserve $requiredField."
        }
    }
    $wprHeapSnapshotTool = Join-Path $resolvedToolsPath 'Invoke-TrackBWprHeapSnapshot.ps1'
    if (-not (Test-Path -LiteralPath $wprHeapSnapshotTool -PathType Leaf)) {
        throw 'WPR heap snapshot helper is missing.'
    }
    $wprHeapSnapshotSource = Get-Content -LiteralPath $wprHeapSnapshotTool -Raw
    foreach ($requiredField in @('HeapSnapshot', 'snapshotconfig', 'singlesnapshot', 'cleanup', 'requires an elevated')) {
        if ($wprHeapSnapshotSource -notmatch [regex]::Escape($requiredField)) {
            throw "WPR heap snapshot helper does not preserve $requiredField."
        }
    }
    $wprResidentSetDecoder = Join-Path $resolvedToolsPath 'Decode-TrackBWprResidentSet.ps1'
    if (-not (Test-Path -LiteralPath $wprResidentSetDecoder -PathType Leaf)) {
        throw 'WPR resident-set decoder is missing.'
    }
    $wprResidentSetSource = Get-Content -LiteralPath $wprResidentSetDecoder -Raw
    foreach ($requiredField in @('resident-set categories', 'private working-set', 'ProcessTreeManifestPath', 'rawTraceRetainedPrivate')) {
        if ($wprResidentSetSource -notmatch [regex]::Escape($requiredField)) {
            throw "WPR resident-set decoder does not preserve $requiredField."
        }
    }
    $wprScenarioCapture = Join-Path $resolvedToolsPath 'Invoke-TrackBWprScenarioHeapCapture.ps1'
    if (-not (Test-Path -LiteralPath $wprScenarioCapture -PathType Leaf)) {
        throw 'WPR scenario heap-capture wrapper is missing.'
    }
    $wprScenarioSource = Get-Content -LiteralPath $wprScenarioCapture -Raw
    foreach ($requiredField in @('static-server-text', 'media-heavy', 'Type READY', 'rendererPid', 'DecodeSymbols', 'decodedOwnershipPath', 'rawTraceRetainedPrivate')) {
        if ($wprScenarioSource -notmatch [regex]::Escape($requiredField)) {
            throw "WPR scenario heap-capture wrapper does not preserve $requiredField."
        }
    }
    $wprScenarioCompare = Join-Path $resolvedToolsPath 'Compare-TrackBWprScenarioPair.ps1'
    if (-not (Test-Path -LiteralPath $wprScenarioCompare -PathType Leaf)) {
        throw 'WPR scenario comparison tool is missing.'
    }
    $wprScenarioCompareSource = Get-Content -LiteralPath $wprScenarioCompare -Raw
    foreach ($requiredField in @('StaticCaptureDirectory', 'MediaCaptureDirectory', 'familyDeltas', 'rawTracesRetainedPrivate')) {
        if ($wprScenarioCompareSource -notmatch [regex]::Escape($requiredField)) {
            throw "WPR scenario comparison does not preserve $requiredField."
        }
    }
    $wprVirtualAllocationCapture = Join-Path $resolvedToolsPath 'Invoke-TrackBWprVirtualAllocationCapture.ps1'
    if (-not (Test-Path -LiteralPath $wprVirtualAllocationCapture -PathType Leaf)) {
        throw 'WPR virtual-allocation capture tool is missing.'
    }
    $wprVirtualAllocationSource = Get-Content -LiteralPath $wprVirtualAllocationCapture -Raw
    foreach ($requiredField in @('VirtualAllocation', 'ProcessId', 'rawTraceRetainedPrivate', 'requires an elevated')) {
        if ($wprVirtualAllocationSource -notmatch [regex]::Escape($requiredField)) {
            throw "WPR virtual-allocation capture does not preserve $requiredField."
        }
    }
    $wprVirtualAllocationSummary = Join-Path $resolvedToolsPath 'Summarize-TrackBWprVirtualAlloc.ps1'
    if (-not (Test-Path -LiteralPath $wprVirtualAllocationSummary -PathType Leaf)) {
        throw 'WPR virtual-allocation sanitizer is missing.'
    }
    $wprVirtualAllocationSummarySource = Get-Content -LiteralPath $wprVirtualAllocationSummary -Raw
    foreach ($requiredField in @('chromium-partitionalloc', 'v8-jit-code', 'double-counted', 'rawOutputRetainedPrivate')) {
        if ($wprVirtualAllocationSummarySource -notmatch [regex]::Escape($requiredField)) {
            throw "WPR virtual-allocation sanitizer does not preserve $requiredField."
        }
    }
    $scenarioSummarySource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Summarize-TrackBFeatureScenarioCaptures.ps1') -Raw
    foreach ($requiredField in @('privateWritableRegionCount', 'privateWritable4MiBTo16MiBResidentMiB', 'privateWritable16MiBOrLargerResidentMiB')) {
        if ($scenarioSummarySource -notmatch [regex]::Escape($requiredField)) {
            throw "Feature-scenario summary does not preserve $requiredField."
        }
    }
    $checkpointSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBMemoryAttributionCheckpoint.ps1') -Raw
    foreach ($requiredField in @('[string] $Scenario', "'-Scenario', `$Scenario")) {
        if ($checkpointSource -notmatch [regex]::Escape($requiredField)) {
            throw "Memory attribution checkpoint does not preserve a caller-supplied scenario label: $requiredField."
        }
    }
    $lifecycleTool = Join-Path $resolvedToolsPath 'Invoke-TrackBLifecycleAttribution.ps1'
    $lifecycleSummaryTool = Join-Path $resolvedToolsPath 'Summarize-TrackBLifecycleAttribution.ps1'
    foreach ($requiredPath in @($lifecycleTool, $lifecycleSummaryTool)) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "Lifecycle attribution tool is missing: $requiredPath"
        }
    }
    $lifecycleSource = Get-Content -LiteralPath $lifecycleTool -Raw
    foreach ($requiredField in @(
        'webview-created-endpoint-ready',
        'discord-url-loading',
        'login-session-restored',
        'application-shell-visible',
        'target-route-loaded',
        'settled-30-seconds',
        'settled-60-seconds',
        'settled-5-minutes',
        'Type READY',
        'renderer-memory-types.json',
        'Get-DescendantProcesses'
    )) {
        if ($lifecycleSource -notmatch [regex]::Escape($requiredField)) {
            throw "Lifecycle attribution does not preserve $requiredField."
        }
    }
    $lifecycleSummarySource = Get-Content -LiteralPath $lifecycleSummaryTool -Raw
    foreach ($requiredField in @('rendererPrivateWorkingSetMedianMiB', 'v8UsedMiB', 'domNodeCount', 'policy')) {
        if ($lifecycleSummarySource -notmatch [regex]::Escape($requiredField)) {
            throw "Lifecycle summary does not preserve $requiredField."
        }
    }
    $frontendCdpTool = Join-Path $resolvedToolsPath 'Invoke-TrackBDiscordFrontendCdp.ps1'
    if (-not (Test-Path -LiteralPath $frontendCdpTool -PathType Leaf)) {
        throw 'Unauthenticated Discord frontend CDP tool is missing.'
    }
    $frontendCdpSource = Get-Content -LiteralPath $frontendCdpTool -Raw
    foreach ($requiredField in @('--diagnostic-discord', '9224', 'heap', 'renderer-resident-types.json', 'rendererPidCrossCheck', 'policy')) {
        if ($frontendCdpSource -notmatch [regex]::Escape($requiredField)) {
            throw "Frontend CDP tool does not preserve $requiredField."
        }
    }
    $navigationTool = Join-Path $resolvedToolsPath 'Invoke-TrackBDiscordFrontendNavigation.ps1'
    $navigationProbe = Join-Path $resolvedToolsPath 'Probe-TrackBDiscordFrontendNavigation.mjs'
    foreach ($requiredPath in @($navigationTool, $navigationProbe)) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "Frontend navigation probe is missing: $requiredPath"
        }
    }
    $navigationProbeSource = Get-Content -LiteralPath $navigationProbe -Raw
    foreach ($requiredField in @('about:blank', 'discord-loaded-before-transition', 'blank-same-renderer-after-navigation', 'discord-restored-after-navigation')) {
        if ($navigationProbeSource -notmatch [regex]::Escape($requiredField)) {
            throw "Frontend navigation probe does not preserve $requiredField."
        }
    }
    $allocationCompareTool = Join-Path $resolvedToolsPath 'Compare-TrackBAllocationBaseGroups.ps1'
    if (-not (Test-Path -LiteralPath $allocationCompareTool -PathType Leaf)) {
        throw 'Allocation-base group comparison tool is missing.'
    }
    $allocationCompareSource = Get-Content -LiteralPath $allocationCompareTool -Raw
    foreach ($requiredField in @('Rank-based aggregate comparison', 'allocationBaseGroups', 'deltaResidentMiB')) {
        if ($allocationCompareSource -notmatch [regex]::Escape($requiredField)) {
            throw "Allocation-base comparison does not preserve $requiredField."
        }
    }
    $blankBoundaryTool = Join-Path $resolvedToolsPath 'Invoke-TrackBBlankResidentBoundary.ps1'
    if (-not (Test-Path -LiteralPath $blankBoundaryTool -PathType Leaf)) {
        throw 'Blank resident boundary tool is missing.'
    }
    $blankBoundarySource = Get-Content -LiteralPath $blankBoundaryTool -Raw
    foreach ($requiredField in @('--diagnostic-blank', 'renderer-resident-types.json', 'did not close normally')) {
        if ($blankBoundarySource -notmatch [regex]::Escape($requiredField)) {
            throw "Blank resident boundary does not preserve $requiredField."
        }
    }
    foreach ($name in @('Invoke-TrackBCanonicalBaseline.ps1', 'Summarize-TrackBCanonicalBaseline.ps1')) {
        $path = Join-Path $resolvedToolsPath $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Canonical baseline tool is missing: $name" }
    }
    $canonicalSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBCanonicalBaseline.ps1') -Raw
    foreach ($requiredField in @('same authenticated account', 'Type READY', 'track-b-canonical-authenticated-static', 'Repetitions')) {
        if ($canonicalSource -notmatch [regex]::Escape($requiredField)) { throw "Canonical baseline runner does not preserve $requiredField." }
    }
    $canonicalSummarySource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Summarize-TrackBCanonicalBaseline.ps1') -Raw
    foreach ($requiredField in @('median', 'p95', 'minimum', 'maximum', 'standardDeviation', 'privateWorkingSetMedianMiB')) {
        if ($canonicalSummarySource -notmatch [regex]::Escape($requiredField)) { throw "Canonical baseline summary does not preserve $requiredField." }
    }
    foreach ($requiredField in @('selfBytes', 'topFunctions')) {
        if ($cdpDiagnosticsSource -notmatch [regex]::Escape($requiredField)) {
            throw "CDP heap sampling does not report $requiredField."
        }
    }
    $phase2SummarySource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Summarize-DiscordPhase2Attribution.ps1') -Raw
    foreach ($requiredField in @('byte-based Measure-DiscordProcessTree output', 'workingSetMiB', 'privateWorkingSetMiB')) {
        if ($phase2SummarySource -notmatch [regex]::Escape($requiredField)) {
            throw "Phase 2 summarizer does not preserve $requiredField."
        }
    }
    $scenarioCompareSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Compare-TrackBScenarioAttribution.ps1') -Raw
    foreach ($requiredField in @('renderer.privateWorkingSetMedianMiB', 'v8.usedMiB', 'media.imageNaturalPixelCount', 'native.image-media.sampledMiB', 'native.gpu-graphics.sampledMiB', 'dom.nodes', 'processAttribution', 'pidMatching')) {
        if ($scenarioCompareSource -notmatch [regex]::Escape($requiredField)) {
            throw "Scenario attribution comparison does not report $requiredField."
        }
    }
    if ($shellSource -notmatch 'Uri\.TryCreate') {
        throw 'Normal bridge origin validation does not parse the message source as a URI.'
    }
    if ($shellSource -notmatch 'UriSchemeHttps') {
        throw 'Normal bridge origin validation does not require HTTPS.'
    }
    if ($shellSource -notmatch '\.discord\.com') {
        throw 'Normal bridge origin validation does not enforce the Discord host boundary.'
    }
    if ($shellSource -notmatch 'webView\.Visible') {
        throw 'Normal shell does not apply an explicit WebView2 control visibility state.'
    }
    if ($shellSource -notmatch 'FormWindowState\.Minimized') {
        throw 'Normal shell does not distinguish minimized window state for WebView2 visibility.'
    }
    if ($shellSource -notmatch 'capability-call') {
        throw 'Diagnostic capability-call instrumentation is missing from the shell source.'
    }
    $measureSource = Get-Content -LiteralPath $measureTool -Raw
    if ($measureSource -notmatch 'TreeRootPid -gt 0.*ProcessId -eq \$TreeRootPid') {
        throw 'Rooted process measurements no longer identify the native shell root.'
    }
    if ($measureSource -notmatch "'native-shell'") {
        throw 'Rooted process measurements do not expose the native-shell role.'
    }
    $timestamps = @(
        '2026-01-01T00:00:00Z',
        '2026-01-01T00:00:05Z',
        '2026-01-01T00:00:10Z'
    )
    $baselineSamples = for ($index = 0; $index -lt $timestamps.Count; $index++) {
        [pscustomobject]@{
            timestamp = $timestamps[$index]
            processCount = 6
            workingSetBytes = (1200 - ($index * 5)) * 1MB
            workingSetPrivateBytes = (700 - ($index * 5)) * 1MB
            workingSetShareableBytes = 500 * 1MB
            privateBytes = (1000 - ($index * 5)) * 1MB
            commitBytes = (1000 - ($index * 5)) * 1MB
            cpuSeconds = 10 + $index
            processes = @(
                [pscustomobject]@{ pid = 101; role = 'browser'; workingSetBytes = 600 * 1MB; workingSetPrivateBytes = 200 * 1MB; privateBytes = 250 * 1MB; handles = 100; threads = 20; cpuSeconds = 5 + $index }
                [pscustomobject]@{ pid = 102; role = 'renderer'; workingSetBytes = 600 * 1MB; workingSetPrivateBytes = 200 * 1MB; privateBytes = 250 * 1MB; handles = 200; threads = 30; cpuSeconds = 5 + $index }
            )
        }
    }
    $candidateSamples = for ($index = 0; $index -lt $timestamps.Count; $index++) {
        [pscustomobject]@{
            timestamp = $timestamps[$index]
            processCount = 6
            workingSetBytes = (1100 - ($index * 5)) * 1MB
            workingSetPrivateBytes = (650 - ($index * 5)) * 1MB
            workingSetShareableBytes = 450 * 1MB
            privateBytes = (900 - ($index * 5)) * 1MB
            commitBytes = (900 - ($index * 5)) * 1MB
            cpuSeconds = 10 + ($index * 0.5)
            processes = @(
                [pscustomobject]@{ pid = 201; role = 'browser'; workingSetBytes = 550 * 1MB; workingSetPrivateBytes = 180 * 1MB; privateBytes = 225 * 1MB; handles = 90; threads = 18; cpuSeconds = 5 + ($index * 0.25) }
                [pscustomobject]@{ pid = 202; role = 'renderer'; workingSetBytes = 550 * 1MB; workingSetPrivateBytes = 180 * 1MB; privateBytes = 225 * 1MB; handles = 180; threads = 27; cpuSeconds = 5 + ($index * 0.25) }
            )
        }
    }
    $baselinePath = Join-Path $tempRoot 'baseline.json'
    $candidatePath = Join-Path $tempRoot 'candidate.json'
    $baseline = [pscustomobject]@{ schemaVersion = 1; build = 'fixture'; scenario = 'fixture'; samples = $baselineSamples }
    $candidate = [pscustomobject]@{ schemaVersion = 1; build = 'fixture'; scenario = 'fixture'; samples = $candidateSamples }
    $baseline | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $baselinePath -Encoding utf8
    $candidate | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $candidatePath -Encoding utf8
    $baselineSummary = Join-Path $tempRoot 'baseline-summary.json'
    $candidateSummary = Join-Path $tempRoot 'candidate-summary.json'
    $comparisonPath = Join-Path $tempRoot 'comparison.json'
    & $summaryTool -InputPath $baselinePath -OutputPath $baselineSummary | Out-Null
    & $summaryTool -InputPath $candidatePath -OutputPath $candidateSummary | Out-Null
    $summaryObject = Get-Content -LiteralPath $candidateSummary -Raw | ConvertFrom-Json
    if ($summaryObject.privateWorkingSetMiB.median -ne 645) {
        throw "Private working-set summary was not calculated as expected."
    }
    if ($summaryObject.commitMiB.median -ne 895) {
        throw "Commit summary was not calculated as expected."
    }
    if ($summaryObject.handles.median -ne 270 -or $summaryObject.threads.median -ne 45) {
        throw "Full-tree handle/thread summary was not calculated as expected."
    }
    if ($summaryObject.rendererCount.median -ne 1 -or $summaryObject.rendererCount.maximum -ne 1) {
        throw "Per-renderer process count summary was not calculated as expected."
    }
    if ($null -eq $summaryObject.roleBreakdown.renderer -or $summaryObject.roleBreakdown.renderer.cpuPercentOfTotal.median -le 0) {
        throw "Role-level CPU attribution was not calculated as expected."
    }
    $phase2InputPath = Join-Path $tempRoot 'phase2.json'
    $phase2OutputPath = Join-Path $tempRoot 'phase2-summary.json'
    $phase2Samples = for ($index = 0; $index -lt $timestamps.Count; $index++) {
        [pscustomobject]@{
            timestamp = $timestamps[$index]
            processCount = 2
            windowState = [pscustomobject]@{ available = $true; visible = $true; minimized = $false; responding = $true }
            processes = @(
                [pscustomobject]@{ pid = 201; parentPid = 101; role = 'browser'; lifetimeSeconds = 20; workingSetMiB = 550; privateWorkingSetMiB = 180; workingSetShareableMiB = 370; privateMemoryMiB = 225; pagedMemoryMiB = 2; handles = 90; threads = 18; cpuPercentOfTotal = 0.1; pageFaultsPerSecond = 1; ioReadBytesPerSecond = 2; ioWriteBytesPerSecond = 3 }
                [pscustomobject]@{ pid = 202; parentPid = 101; role = 'renderer'; lifetimeSeconds = 20; workingSetMiB = 550; privateWorkingSetMiB = 180; workingSetShareableMiB = 370; privateMemoryMiB = 225; pagedMemoryMiB = 2; handles = 180; threads = 27; cpuPercentOfTotal = 0.2; pageFaultsPerSecond = 1; ioReadBytesPerSecond = 2; ioWriteBytesPerSecond = 3 }
            )
        }
    }
    [pscustomobject]@{ schemaVersion = 1; scenario = 'fixture'; rootPid = 101; environment = [pscustomobject]@{ displayRefreshRate = 60; displayWidth = 1920; displayHeight = 1080 }; samples = $phase2Samples } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $phase2InputPath -Encoding utf8
    & $phase2SummaryTool -InputPath $phase2InputPath -OutputPath $phase2OutputPath | Out-Null
    $phase2Summary = Get-Content -LiteralPath $phase2OutputPath -Raw | ConvertFrom-Json
    $rendererPidSummary = @($phase2Summary.processes | Where-Object { $_.pid -eq 202 })
    if ($rendererPidSummary.Count -ne 1 -or $rendererPidSummary[0].role -ne 'renderer' -or $rendererPidSummary[0].privateWorkingSetMedianMiB -ne 180) {
        throw "Per-PID renderer attribution was not preserved in the Phase 2 summary."
    }
    $comparison = & $compareTool -BaselineSummary $baselineSummary -CandidateSummary $candidateSummary -OutputPath $comparisonPath | ConvertFrom-Json
    if (-not $comparison.passed) {
        throw 'Synthetic benchmark comparison did not pass.'
    }
    $shareableMetric = @($comparison.metrics | Where-Object name -eq 'shareableWorkingSetMedianMiB')
    if ($shareableMetric.Count -ne 1 -or $shareableMetric[0].candidate -ne 450) {
        throw 'Shareable working-set comparison was not calculated as expected.'
    }

    $treeFixturePath = Join-Path $tempRoot 'tree.json'
    $cdpFixturePath = Join-Path $tempRoot 'cdp.json'
    $joinFixturePath = Join-Path $tempRoot 'join.json'
    $treeFixture = [pscustomobject]@{
        samples = @([pscustomobject]@{
            processes = @(
                [pscustomobject]@{ pid = 301; role = 'renderer'; workingSetPrivateBytes = 100 * 1MB; privateBytes = 120 * 1MB; handles = 10; threads = 5 }
                [pscustomobject]@{ pid = 302; role = 'crashpad-handler'; workingSetPrivateBytes = 2 * 1MB; privateBytes = 3 * 1MB; handles = 4; threads = 2 }
            )
        })
    }
    $cdpFixture = [pscustomobject]@{
        processes = @(
            [pscustomobject]@{ id = 301; type = 'renderer'; cpuTime = 1.25 }
            [pscustomobject]@{ id = 303; type = 'GPU'; cpuTime = 0.5 }
        )
    }
    $treeFixture | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $treeFixturePath -Encoding utf8
    $cdpFixture | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $cdpFixturePath -Encoding utf8
    & $joinTool -ProcessTreePath $treeFixturePath -CdpProcessInfoPath $cdpFixturePath -OutputPath $joinFixturePath | Out-Null
    $joinFixture = Get-Content -LiteralPath $joinFixturePath -Raw | ConvertFrom-Json
    if ($joinFixture.matchedCount -ne 1 -or $joinFixture.joinedProcesses[0].cdpType -ne 'renderer') {
        throw 'CDP-to-Windows attribution join fixture did not preserve the expected match boundary.'
    }

    $traceBaselinePath = Join-Path $tempRoot 'trace-baseline.json'
    $traceCandidatePath = Join-Path $tempRoot 'trace-candidate.json'
    $traceComparisonPath = Join-Path $tempRoot 'trace-comparison.json'
    $traceEvents = [pscustomobject]@{
        selectedCounts = [pscustomobject]@{ RunTask = 10; EvaluateScript = 0; FunctionCall = 0; UpdateLayoutTree = 0; Layout = 0; Paint = 0; CompositeLayers = 0; DrawFrame = 0; memory_dump = 0; periodic_interval = 2 }
        eventDurationsMicroseconds = @([pscustomobject]@{ key = 'RunTask'; count = 1000 })
    }
    [pscustomobject]@{ durationSeconds = 5; dataLossOccurred = $false; summary = $traceEvents } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $traceBaselinePath -Encoding utf8
    [pscustomobject]@{ durationSeconds = 10; dataLossOccurred = $false; summary = $traceEvents } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $traceCandidatePath -Encoding utf8
    $traceComparison = & $traceCompareTool -BaselinePath $traceBaselinePath -CandidatePath $traceCandidatePath -OutputPath $traceComparisonPath | ConvertFrom-Json
    $runTaskMetric = @($traceComparison.metrics | Where-Object event -eq 'RunTask')
    if ($runTaskMetric.Count -ne 1 -or $runTaskMetric[0].baselinePerSecond -ne 2 -or $runTaskMetric[0].candidatePerSecond -ne 1) {
        throw 'CDP trace comparison did not normalize event counts per second.'
    }

    $acceptanceCandidatePath = Join-Path $tempRoot 'acceptance-candidate.json'
    $acceptanceFunctionalPath = Join-Path $tempRoot 'acceptance-functional.json'
    $acceptanceVisualPath = Join-Path $tempRoot 'acceptance-visual.json'
    $acceptanceOutputPath = Join-Path $tempRoot 'acceptance-output.json'
    $functionalFixtureResults = @('login-session', 'servers-channels', 'messaging', 'images-media', 'notifications', 'voice', 'video', 'screen-share', 'file-dialogs', 'clipboard-drag-drop', 'window-shell', 'accessibility') | ForEach-Object {
        [pscustomobject]@{ id = $_; status = 'PASS' }
    }
    [pscustomobject]@{
        builds = @('KoroneDiscordShell')
        workingSetMiB = [pscustomobject]@{ median = 200; p95 = 220 }
        privateWorkingSetMiB = [pscustomobject]@{ median = 150; p95 = 245 }
        privateMemoryMiB = [pscustomobject]@{ median = 240; p95 = 245 }
        processCount = [pscustomobject]@{ median = 8; maximum = 8 }
        cpuPercentOfTotal = [pscustomobject]@{ medianRun = 0.1; p95Run = 0.15 }
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceCandidatePath -Encoding utf8
    [pscustomobject]@{ processName = 'KoroneDiscordShell'; passed = $true; results = $functionalFixtureResults } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceFunctionalPath -Encoding utf8
    [pscustomobject]@{ parityReady = $true; visualReviewPassed = $true; screenshotComparison = [pscustomobject]@{ width = 1920; height = 1080; differingPixelPercent = 0; meanAbsoluteChannelError = 0; p95PixelError = 0 } } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceVisualPath -Encoding utf8
    $acceptanceResultText = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath -OutputPath $acceptanceOutputPath
    $acceptanceResult = $acceptanceResultText | ConvertFrom-Json
    if (-not $acceptanceResult.passed) {
        throw "Synthetic Track B acceptance gate should pass when every gate is satisfied: $($acceptanceResult | ConvertTo-Json -Compress)"
    }
    $candidateBuildFixture = Get-Content -LiteralPath $acceptanceCandidatePath -Raw | ConvertFrom-Json
    $candidateBuildFixture.builds = @('DiscordPTB')
    $candidateBuildFixture | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $acceptanceCandidatePath -Encoding utf8
    $wrongBuildText = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath
    $wrongBuildResult = $wrongBuildText | ConvertFrom-Json
    if ($wrongBuildResult.passed -or $wrongBuildResult.candidateBuildValid) {
        throw 'Acceptance gate must reject a resource summary attributed to the stock Discord build.'
    }
    $candidateBuildFixture.builds = @('KoroneDiscordShell')
    $candidateBuildFixture | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $acceptanceCandidatePath -Encoding utf8
    [pscustomobject]@{ processName = 'DiscordPTB'; passed = $true; results = $functionalFixtureResults } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceFunctionalPath -Encoding utf8
    $wrongProcessText = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath
    $wrongProcessResult = $wrongProcessText | ConvertFrom-Json
    if ($wrongProcessResult.passed -or $wrongProcessResult.functionalProcessValid) {
        throw 'Acceptance gate must reject functional results attributed to the stock Discord process.'
    }
    [pscustomobject]@{ processName = 'KoroneDiscordShell'; passed = $true; results = $functionalFixtureResults } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceFunctionalPath -Encoding utf8
    [pscustomobject]@{
        builds = @('KoroneDiscordShell')
        workingSetMiB = [pscustomobject]@{ median = 200; p95 = 220 }
        privateWorkingSetMiB = [pscustomobject]@{ median = 150; p95 = 251 }
        privateMemoryMiB = [pscustomobject]@{ median = 240; p95 = 245 }
        processCount = [pscustomobject]@{ median = 8; maximum = 8 }
        cpuPercentOfTotal = [pscustomobject]@{ medianRun = 0.1; p95Run = 0.15 }
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceCandidatePath -Encoding utf8
    $highWorkingSetP95Text = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath
    $highWorkingSetP95Result = $highWorkingSetP95Text | ConvertFrom-Json
    if ($highWorkingSetP95Result.passed) {
        throw 'Acceptance gate must reject a private-working-set p95 over the target even when the median passes.'
    }
    [pscustomobject]@{
        builds = @('KoroneDiscordShell')
        workingSetMiB = [pscustomobject]@{ median = 200; p95 = 220 }
        privateWorkingSetMiB = [pscustomobject]@{ median = 150; p95 = 245 }
        privateMemoryMiB = [pscustomobject]@{ median = 240; p95 = 251 }
        processCount = [pscustomobject]@{ median = 8; maximum = 8 }
        cpuPercentOfTotal = [pscustomobject]@{ medianRun = 0.1; p95Run = 0.15 }
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceCandidatePath -Encoding utf8
    $highPrivateBytesP95Text = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath
    $highPrivateBytesP95Result = $highPrivateBytesP95Text | ConvertFrom-Json
    if (-not $highPrivateBytesP95Result.passed -or -not $highPrivateBytesP95Result.resourcePassed -or $highPrivateBytesP95Result.measurementEvidence.privateBytesP95MiB -ne 251) {
        throw 'Acceptance gate must keep private-bytes p95 as reported corroborating evidence rather than treating it as the primary resident-memory gate.'
    }
    [pscustomobject]@{
        builds = @('KoroneDiscordShell')
        workingSetMiB = [pscustomobject]@{ median = 200; p95 = 220 }
        privateWorkingSetMiB = [pscustomobject]@{ median = 150; p95 = 245 }
        privateMemoryMiB = [pscustomobject]@{ median = 240; p95 = 245 }
        processCount = [pscustomobject]@{ median = 8; maximum = 8 }
        cpuPercentOfTotal = [pscustomobject]@{ medianRun = 0.1; p95Run = 0.9 }
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceCandidatePath -Encoding utf8
    $highCpuP95Text = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath
    $highCpuP95Result = $highCpuP95Text | ConvertFrom-Json
    if (-not $highCpuP95Result.passed -or -not $highCpuP95Result.resourcePassed -or $highCpuP95Result.measurementEvidence.cpuP95PercentOfTotal -ne 0.9) {
        throw 'Acceptance gate must use settled-idle CPU median as the hard criterion while preserving CPU p95 in the report.'
    }
    [pscustomobject]@{ processName = 'KoroneDiscordShell'; passed = $true; results = @([pscustomobject]@{ id = 'messaging'; status = 'PASS' }) } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceFunctionalPath -Encoding utf8
    $incompleteFunctionalText = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath
    $incompleteFunctionalResult = $incompleteFunctionalText | ConvertFrom-Json
    if ($incompleteFunctionalResult.passed -or $incompleteFunctionalResult.functionalCoverageComplete) {
        throw 'Acceptance gate must reject an incomplete functional checklist.'
    }
    [pscustomobject]@{ processName = 'KoroneDiscordShell'; passed = $true; results = $functionalFixtureResults } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceFunctionalPath -Encoding utf8
    [pscustomobject]@{ parityReady = $true; visualReviewPassed = $true; screenshotComparison = [pscustomobject]@{ differingPixelPercent = 0 } } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceVisualPath -Encoding utf8
    $malformedVisualText = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath
    $malformedVisualResult = $malformedVisualText | ConvertFrom-Json
    if ($malformedVisualResult.passed -or $malformedVisualResult.visualComparisonValid) {
        throw 'Acceptance gate must reject an incomplete screenshot comparison object.'
    }
    [pscustomobject]@{
        builds = @('KoroneDiscordShell')
        workingSetMiB = [pscustomobject]@{ median = 200; p95 = 220 }
        privateWorkingSetMiB = [pscustomobject]@{ median = 150; p95 = 245 }
        privateMemoryMiB = [pscustomobject]@{ median = 240; p95 = 245 }
        processCount = [pscustomobject]@{ median = 8; maximum = 8 }
        cpuPercentOfTotal = [pscustomobject]@{ medianRun = 0.1; p95Run = 0.15 }
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceCandidatePath -Encoding utf8
    [pscustomobject]@{ parityReady = $true; visualReviewPassed = $false; screenshotComparison = [pscustomobject]@{ width = 1920; height = 1080; differingPixelPercent = 0; meanAbsoluteChannelError = 0; p95PixelError = 0 } } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceVisualPath -Encoding utf8
    $rejectedAcceptanceText = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath
    $rejectedAcceptanceResult = $rejectedAcceptanceText | ConvertFrom-Json
    if ($rejectedAcceptanceResult.passed) {
        throw 'Synthetic Track B acceptance gate should fail without explicit visual review.'
    }
    [pscustomobject]@{ processName = 'KoroneDiscordShell'; passed = 'false'; results = $functionalFixtureResults } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceFunctionalPath -Encoding utf8
    $stringBooleanText = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath
    $stringBooleanResult = $stringBooleanText | ConvertFrom-Json
    if ($stringBooleanResult.passed) {
        throw 'Acceptance gate must reject string values that resemble true booleans.'
    }
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

[pscustomobject]@{
    toolCount = $scripts.Count
    parsed = $true
    benchmarkFixturePassed = $true
    toolsPath = $resolvedToolsPath
}
$global:LASTEXITCODE = 0
