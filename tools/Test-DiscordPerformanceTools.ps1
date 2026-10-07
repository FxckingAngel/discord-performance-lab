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
$cdpDiagnosticTool = Join-Path $resolvedToolsPath 'Invoke-DiscordPhase2CdpDiagnostics.mjs'
$featureProbeTool = Join-Path $resolvedToolsPath 'Probe-DiscordFeatureSupport.mjs'
$mediaQualityProbeTool = Join-Path $resolvedToolsPath 'Probe-DiscordMediaQuality.mjs'
$mediaQualityCompareTool = Join-Path $resolvedToolsPath 'Compare-DiscordMediaQuality.mjs'
$mediaCheckpointTool = Join-Path $resolvedToolsPath 'Invoke-TrackBMediaCheckpoint.ps1'
$mediaTransitionSummaryTool = Join-Path $resolvedToolsPath 'Summarize-TrackBMediaTransition.ps1'
$clipboardBridgeTool = Join-Path $resolvedToolsPath 'Test-TrackBClipboardBridge.mjs'
$desktopParityOracleTool = Join-Path $resolvedToolsPath 'Probe-DiscordDesktopParityOracle.mjs'
$desktopParityOracleLauncher = Join-Path $resolvedToolsPath 'Invoke-DiscordDesktopParityOracle.ps1'
$windowBridgeTestTool = Join-Path $resolvedToolsPath 'Test-TrackBWindowBridge.mjs'
$powerMonitorLauncher = Join-Path $resolvedToolsPath 'Invoke-TrackBPowerMonitorTest.ps1'
$powerMonitorTestTool = Join-Path $resolvedToolsPath 'Test-TrackBPowerMonitor.mjs'
$clipboardBridgeLauncher = Join-Path $resolvedToolsPath 'Invoke-TrackBClipboardBridgeTest.ps1'
$fileDialogLauncher = Join-Path $resolvedToolsPath 'Invoke-TrackBFileDialogTest.ps1'
$bootContractLauncher = Join-Path $resolvedToolsPath 'Invoke-TrackBBootContractActivationTest.ps1'
$processUtilsHostTest = Join-Path $resolvedToolsPath 'Test-TrackBProcessUtilsHostObject.ps1'
$nativeFamilyLifecycleTool = Join-Path $resolvedToolsPath 'Invoke-TrackBNativeFamilyLifecycle.ps1'
$allocationBaseWatchTool = Join-Path $resolvedToolsPath 'Watch-TrackBAllocationBases.ps1'
$screenshotCompareTool = Join-Path $resolvedToolsPath 'Compare-DiscordScreenshots.py'
$smokeTool = Join-Path $resolvedToolsPath 'Test-TrackBShellSmoke.ps1'
$buildTool = Join-Path $resolvedToolsPath 'Build-TrackBShell.ps1'
$lifecycleTool = Join-Path $resolvedToolsPath 'Invoke-TrackBLifecycleAttribution.ps1'
$shellSourcePath = Join-Path (Split-Path -Parent $resolvedToolsPath) 'track-b/discord-shell/MainForm.cs'
$programSourcePath = Join-Path (Split-Path -Parent $resolvedToolsPath) 'track-b/discord-shell/Program.cs'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('discord-performance-lab-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
    if (-not (Test-Path -LiteralPath $buildTool -PathType Leaf)) {
        throw 'Track B build tool is missing.'
    }
    $buildSource = Get-Content -LiteralPath $buildTool -Raw
    foreach ($requiredField in @('$root = Split-Path -Parent $PSScriptRoot', 'ClipboardHostObject.cs', 'FileDialogHostObject.cs', 'ProcessUtilsHostObject.cs', 'SafeStorageHostObject.cs', 'WindowsClipboardBackend.cs', "Copy-Item -LiteralPath (Join-Path `$root 'track-b\discord-shell\web')")) {
        if ($buildSource -notmatch [regex]::Escape($requiredField)) {
            throw "Track B build tool is missing $requiredField."
        }
    }
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
    foreach ($requiredField in @('visualReviewPassed', 'MediaQualityReport', 'mediaQuality', 'mediaQualityProvenance')) {
        if ($visualCheckpointSource -notmatch [regex]::Escape($requiredField)) {
            throw "Visual checkpoint is missing $requiredField."
        }
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
if (-not (Test-Path -LiteralPath $mediaQualityProbeTool -PathType Leaf)) {
    throw 'Media-quality probe is missing.'
}
if (-not (Test-Path -LiteralPath $mediaQualityCompareTool -PathType Leaf)) {
    throw 'Media-quality comparison tool is missing.'
}
$mediaQualityCompareSource = Get-Content -LiteralPath $mediaQualityCompareTool -Raw
foreach ($requiredField in @('sourceResolutionComparable', 'rasterQualityComparable', 'hardwareAccelerationEnabled', 'visualQualityComparable')) {
    if ($mediaQualityCompareSource -notmatch [regex]::Escape($requiredField)) {
        throw "Media-quality comparison is missing $requiredField."
    }
}
if (-not (Test-Path -LiteralPath $mediaCheckpointTool -PathType Leaf)) {
    throw 'Active media checkpoint workflow is missing.'
}
if (-not (Test-Path -LiteralPath $windowBridgeTestTool -PathType Leaf)) {
    throw 'Window bridge runtime test is missing.'
}
$windowBridgeTestSource = Get-Content -LiteralPath $windowBridgeTestTool -Raw
foreach ($requiredField in @('setAlwaysOnTop', 'isAlwaysOnTop', 'setMinimumSize', 'stateChanged', 'stateRestored')) {
    if ($windowBridgeTestSource -notmatch [regex]::Escape($requiredField)) {
        throw "Window bridge runtime test is missing $requiredField."
    }
}
foreach ($isolatedLauncher in @(
        @{ path = $clipboardBridgeLauncher; fields = @('--diagnostic-clipboard', '9241', 'normalShellRestoredPid') },
        @{ path = $fileDialogLauncher; fields = @('--diagnostic-file-dialog', '9240', 'normalShellRestoredPid') },
        @{ path = $bootContractLauncher; fields = @('--diagnostic-boot-contract-complete', '9239', 'bootContractActivation', 'normalShellRestoredPid') }
    )) {
    if (-not (Test-Path -LiteralPath $isolatedLauncher.path -PathType Leaf)) {
        throw "Isolated capability launcher is missing: $($isolatedLauncher.path)"
    }
    $launcherSource = Get-Content -LiteralPath $isolatedLauncher.path -Raw
    foreach ($requiredField in $isolatedLauncher.fields) {
        if ($launcherSource -notmatch [regex]::Escape($requiredField)) {
            throw "Isolated capability launcher is missing $requiredField."
        }
    }
}
if (-not (Test-Path -LiteralPath $processUtilsHostTest -PathType Leaf)) {
    throw 'Process-utils host-object test is missing.'
}
$processUtilsSource = Get-Content -LiteralPath $processUtilsHostTest -Raw
foreach ($requiredField in @('ProcessUtilsHostObject', 'GetCPUCoreCount', 'GetCurrentCPUUsagePercent', 'GetProcessUptime', 'cpuPercentRangeValid')) {
    if ($processUtilsSource -notmatch [regex]::Escape($requiredField)) {
        throw "Process-utils host-object test is missing $requiredField."
    }
}
if (-not (Test-Path -LiteralPath $mediaTransitionSummaryTool -PathType Leaf)) {
    throw 'Media-transition summary tool is missing.'
}
$mediaTransitionSummarySource = Get-Content -LiteralPath $mediaTransitionSummaryTool -Raw
foreach ($requiredField in @('$FunctionalPass', '$MediaQualityPass', 'allocationFamiliesMiB', 'allocationFamilyKeys', 'Sort-Object -Unique', 'optimizationEligible')) {
    if ($mediaTransitionSummarySource -notmatch [regex]::Escape($requiredField)) {
        throw "Media-transition summary tool is missing $requiredField."
    }
}
if (-not (Test-Path -LiteralPath $clipboardBridgeTool -PathType Leaf)) {
    throw 'Clipboard bridge probe is missing.'
}
$clipboardBridgeSource = Get-Content -LiteralPath $clipboardBridgeTool -Raw
foreach ($requiredField in @('copyImage', 'copyFile', 'hasMixedContent', 'syntheticRoundTripPassed', 'noUserClipboardAccess')) {
    if ($clipboardBridgeSource -notmatch [regex]::Escape($requiredField)) {
        throw "Clipboard bridge probe is missing $requiredField."
    }
}
$mediaCheckpointSource = Get-Content -LiteralPath $mediaCheckpointTool -Raw
foreach ($requiredField in @('voice-permission', 'voice-call', 'video-call', 'screen-share', 'READY', 'official Discord reference was not touched', 'Measure-DiscordProcessTree.ps1', 'Probe-DiscordMediaQuality.mjs', '9232', 'mediaQualityPath', 'readyConfirmed', 'processTreePath')) {
    if ($mediaCheckpointSource -notmatch [regex]::Escape($requiredField)) {
        throw "Active media checkpoint workflow is missing $requiredField."
    }
}
$featureCheckpointSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBFeatureScenarioCheckpoint.ps1') -Raw
foreach ($requiredField in @('ToUniversalTime().ToString(''o'')', 'rootIdentityStable')) {
    if ($featureCheckpointSource -notmatch [regex]::Escape($requiredField)) {
        throw "Feature checkpoint does not normalize process creation times: $requiredField"
    }
}
$processTreeSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Measure-DiscordProcessTree.ps1') -Raw
foreach ($requiredField in @('firstPrivateWorkingSetMiB', 'lastPrivateWorkingSetMiB', 'firstPrivateBytesMiB', 'lastPrivateBytesMiB')) {
    if ($processTreeSource -notmatch [regex]::Escape($requiredField)) {
        throw "Process-tree summary does not label $requiredField explicitly."
    }
}
$environmentProbeWrapperSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBEnvironmentProbe.ps1') -Raw
foreach ($requiredField in @('DiagnosticArgument', '9224', 'fixed CDP port')) {
    if ($environmentProbeWrapperSource -notmatch [regex]::Escape($requiredField)) {
        throw "Environment probe wrapper does not preserve $requiredField."
    }
}
$mainFormSource = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $resolvedToolsPath) 'track-b/discord-shell/MainForm.cs') -Raw
if ($mainFormSource -match 'diagnosticAuthenticated \|\| diagnosticAuthenticatedCapabilityEvents\s*\r?\n\s*\? "WebView2UserData"\s*:\s*diagnosticAuthenticatedCapabilityEvents') {
    throw 'Authenticated capability-events profile selection contains an unreachable branch.'
}
foreach ($oracleTool in @($desktopParityOracleTool, $desktopParityOracleLauncher)) {
        if (-not (Test-Path -LiteralPath $oracleTool -PathType Leaf)) {
            throw "Desktop parity oracle tool is missing: $oracleTool"
        }
    }
    if (-not (Test-Path -LiteralPath $nativeFamilyLifecycleTool -PathType Leaf)) {
        throw 'Native-family lifecycle tool is missing.'
    }
    if (-not (Test-Path -LiteralPath $allocationBaseWatchTool -PathType Leaf)) {
        throw 'Allocation-base watch tool is missing.'
    }
    $allocationBaseWatchSource = Get-Content -LiteralPath $allocationBaseWatchTool -Raw
    foreach ($requiredField in @('Measure-TrackBResidentMemoryTypes.ps1', 'allocationBaseSummary', 'Read-only per-process allocation-base watch')) {
        if ($allocationBaseWatchSource -notmatch [regex]::Escape($requiredField)) {
            throw "Allocation-base watch tool is missing $requiredField."
        }
    }
    $nativeFamilyLifecycleSource = Get-Content -LiteralPath $nativeFamilyLifecycleTool -Raw
    foreach ($requiredField in @("Name -ne 'msedgewebview2.exe'", '--type=renderer', '--webview-exe-name=KoroneDiscordShell\.exe', '9228', 'rendererPid')) {
        if ($nativeFamilyLifecycleSource -notmatch [regex]::Escape($requiredField)) {
            throw "Native-family lifecycle tool is missing $requiredField."
        }
    }
    $mediaQualityProbeSource = Get-Content -LiteralPath $mediaQualityProbeTool -Raw
    foreach ($requiredField in @('naturalWidth', 'naturalHeight', 'displayedWidth', 'devicePixelRatio', 'requestedSourceHints', 'GPU.getInfo', 'No URLs')) {
        if ($mediaQualityProbeSource -notmatch [regex]::Escape($requiredField)) {
            throw "Media-quality probe does not preserve $requiredField."
        }
    }
    $cdpSource = Get-Content -LiteralPath $cdpDiagnosticTool -Raw
    foreach ($requiredField in @('applicationReadiness', 'discordMountPresent', 'documentReadyState', 'domReady', 'domNodeCount', 'appMountRect')) {
        if ($cdpSource -notmatch [regex]::Escape($requiredField)) {
            throw "CDP diagnostic tool is missing $requiredField."
        }
    }
    $phase2AttributionSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Measure-DiscordPhase2Attribution.ps1') -Raw
    foreach ($requiredField in @('Refusing to mislabel the capture', 'rootCim.Name')) {
        if ($phase2AttributionSource -notmatch [regex]::Escape($requiredField)) {
            throw "Phase 2 attribution does not validate the requested root process identity: $requiredField"
        }
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
    foreach ($requiredField in @('[switch] $Automatic', "mode = if (`$Automatic) { 'automatic-unverified' } else { 'manual-checkpoint' }", 'Capture-Checkpoint $checkpoint.label $checkpoint.instruction -SkipReady', '-RequireApplicationReady', 'applicationReady', 'Automatic unverified', 'bin/Release/net8.0-windows/KoroneDiscordShell.exe', '$measureHost', 'RedirectStandardError', 'process-capture.stderr.log', "'-ProcessName', 'KoroneDiscordShell'")) {
        if ($lifecycleSource -notmatch [regex]::Escape($requiredField)) {
            throw "Lifecycle attribution does not preserve automatic unverified checkpoints: $requiredField"
        }
    }
    $lifecycleSummarySource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Summarize-TrackBLifecycleAttribution.ps1') -Raw
    foreach ($requiredField in @("[string]`$manifest.mode -eq 'automatic-unverified'", 'Automatic timed checkpoints are unverified', 'applicationReady')) {
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
    foreach ($requiredField in @('workingSetMiB', 'privateWorkingSetMiB', 'privateMemoryMiB', 'processCount', 'cpuPercentOfTotal', 'candidateBuildValid', 'functionalProcessValid', 'functionalCoverageComplete', 'functionalWindowResponsive', 'mediaEvidenceComplete', 'mediaEvidenceMissingIds', 'functionalPassed', 'visualPassed', 'visualComparisonValid', 'measurementEvidence')) {
        if ($acceptanceGateSource -notmatch [regex]::Escape($requiredField)) {
            throw "Track B acceptance gate does not evaluate $requiredField."
        }
    }
    foreach ($functionalId in @('login-session', 'servers-channels', 'messaging', 'images-media', 'notifications', 'voice', 'video', 'screen-share', 'file-dialogs', 'clipboard-drag-drop', 'window-shell', 'accessibility')) {
        if ($functionalCheckpointSource -notmatch [regex]::Escape($functionalId) -or $acceptanceGateSource -notmatch [regex]::Escape($functionalId)) {
            throw "Functional checklist ID is not synchronized between the checkpoint and acceptance gate: $functionalId"
        }
    }
    $bootActivationSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Test-TrackBBootContractActivation.mjs') -Raw
    foreach ($requiredField in @("readyState === 'complete'", 'domNodeCount >= 100', 'appMountRect.width > 0', 'appMountRect.height > 0')) {
        if ($bootActivationSource -notmatch [regex]::Escape($requiredField)) {
            throw "Boot-contract activation gate is missing $requiredField."
        }
    }
    $shellSource = Get-Content -LiteralPath $shellSourcePath -Raw
    $programSource = Get-Content -LiteralPath $programSourcePath -Raw
    foreach ($requiredField in @('SetProcessDpiAwarenessContext', 'PerMonitorAwareV2', 'ApplicationConfiguration.Initialize')) {
        if ($programSource -notmatch [regex]::Escape($requiredField)) {
            throw "Track B startup DPI setup is missing $requiredField."
        }
    }
    if ($programSource.IndexOf('SetProcessDpiAwarenessContext') -gt $programSource.IndexOf('ApplicationConfiguration.Initialize')) {
        throw 'Track B process DPI awareness is configured after WinForms initialization.'
    }
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
    $programSource = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $shellSourcePath) 'Program.cs') -Raw
    if ($programSource -notmatch 'diagnostic-desktop-hints') {
        throw 'Desktop-hints diagnostic mode is not wired into the shell entry point.'
    }
    if ($shellSource -notmatch 'Network\.setUserAgentOverride' -or $shellSource -notmatch 'userAgentMetadata') {
        throw 'Desktop-hints diagnostic mode does not set the evidence-backed client-hints surface.'
    }
    $desktopHintsLauncher = Join-Path $resolvedToolsPath 'Launch-TrackBDesktopHintsDiagnostic.ps1'
    if (-not (Test-Path -LiteralPath $desktopHintsLauncher -PathType Leaf)) {
        throw 'Desktop-hints diagnostic launcher is missing.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $resolvedToolsPath 'Launch-TrackBNormal.ps1') -PathType Leaf)) {
        throw 'Normal Track B launcher is missing.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $resolvedToolsPath 'Launch-TrackBAuthenticatedNoBridges.ps1') -PathType Leaf)) {
        throw 'Authenticated no-bridge launcher is missing.'
    }
    $friendsNavigationSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Navigate-TrackBFriends.mjs') -Raw
    foreach ($requiredToken in @('discord.com/channels/@me', 'discord-channels', 'targetOrigin', 'raw URLs')) {
        if ($friendsNavigationSource -notmatch [regex]::Escape($requiredToken)) {
            throw "Friends route checkpoint is missing $requiredToken."
        }
    }
    $windowStateTest = Join-Path $resolvedToolsPath 'Invoke-TrackBWindowBridgeStateTest.ps1'
    if (-not (Test-Path -LiteralPath $windowStateTest -PathType Leaf)) {
        throw 'Window bridge state test is missing.'
    }
    $windowStateSource = Get-Content -LiteralPath $windowStateTest -Raw
    foreach ($requiredField in @('IsIconic', 'diagnostic-window-bridge', 'minimize', 'restore', 'nativeStateObserved', 'officialDiscordTouched')) {
        if ($windowStateSource -notmatch [regex]::Escape($requiredField)) {
            throw "Window bridge state test does not preserve $requiredField."
        }
    }
    $clipboardBridgeTest = Join-Path $resolvedToolsPath 'Test-TrackBClipboardBridge.mjs'
    $clipboardBridgeLauncher = Join-Path $resolvedToolsPath 'Invoke-TrackBClipboardBridgeTest.ps1'
    $clipboardHostSource = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $resolvedToolsPath) 'track-b/discord-shell/ClipboardHostObject.cs') -Raw
    $clipboardBridgeSource = Get-Content -LiteralPath $clipboardBridgeTest -Raw
    $clipboardLauncherSource = Get-Content -LiteralPath $clipboardBridgeLauncher -Raw
    foreach ($requiredField in @('SyntheticClipboardBackend', 'syntheticRoundTripPassed', 'noUserClipboardAccess', 'diagnostic-clipboard', '9241')) {
        if ($clipboardHostSource -notmatch [regex]::Escape($requiredField) -and $clipboardBridgeSource -notmatch [regex]::Escape($requiredField) -and $clipboardLauncherSource -notmatch [regex]::Escape($requiredField)) {
            throw "Clipboard diagnostic contract does not preserve $requiredField."
        }
    }
    if ($shellSource -notmatch 'new ClipboardHostObject\(new SyntheticClipboardBackend\(\)\)') {
        throw 'Clipboard diagnostic does not use a synthetic backend.'
    }
    $fileDialogTest = Join-Path $resolvedToolsPath 'Test-TrackBFileDialog.mjs'
    $fileDialogLauncher = Join-Path $resolvedToolsPath 'Invoke-TrackBFileDialogTest.ps1'
    $fileDialogSource = Get-Content -LiteralPath $fileDialogTest -Raw
    $fileDialogLauncherSource = Get-Content -LiteralPath $fileDialogLauncher -Raw
    $fileDialogHostSource = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $resolvedToolsPath) 'track-b/discord-shell/FileDialogHostObject.cs') -Raw
    foreach ($requiredField in @('diagnostic-file-dialog', '9240', 'invalidPropertyRejected', 'malformedFilterRejected', 'noDialogOpened', 'ShowOpenDialog')) {
        if ($fileDialogHostSource -notmatch [regex]::Escape($requiredField) -and $fileDialogSource -notmatch [regex]::Escape($requiredField) -and $fileDialogLauncherSource -notmatch [regex]::Escape($requiredField)) {
            throw "File-dialog diagnostic contract does not preserve $requiredField."
        }
    }
    if ($shellSource -notmatch 'new FileDialogHostObject\(\)') {
        throw 'File-dialog diagnostic does not use the native host implementation.'
    }
    $hardwareBridgeLauncher = Join-Path $resolvedToolsPath 'Invoke-TrackBHardwareBridgeTest.ps1'
    if (-not (Test-Path -LiteralPath $hardwareBridgeLauncher -PathType Leaf)) {
        throw 'Hardware bridge launcher is missing.'
    }
    $hardwareBridgeSource = Get-Content -LiteralPath $hardwareBridgeLauncher -Raw
    foreach ($requiredField in @('diagnostic-hardware-bridge', 'getDisplayCount', 'System.Windows.Forms.Screen', 'nativeDisplayCount', 'displayMetricsExposed', 'nativeStateObserved', 'officialDiscordTouched')) {
        if ($hardwareBridgeSource -notmatch [regex]::Escape($requiredField)) {
            throw "Hardware bridge verification does not preserve $requiredField."
        }
    }
    $notificationDiagnosticTest = Join-Path $resolvedToolsPath 'Test-TrackBNotificationDiagnostic.ps1'
    if (-not (Test-Path -LiteralPath $notificationDiagnosticTest -PathType Leaf)) {
        throw 'Notification diagnostic test is missing.'
    }
    $notificationDiagnosticSource = Get-Content -LiteralPath $notificationDiagnosticTest -Raw
    foreach ($requiredField in @('diagnostic-capability-events', 'notificationContentRecorded', 'officialDiscordTouched', 'e.Title', 'e.Body')) {
        if ($notificationDiagnosticSource -notmatch [regex]::Escape($requiredField)) {
            throw "Notification diagnostic contract does not preserve $requiredField."
        }
    }
    $lifecycleSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBLifecycleAttribution.ps1') -Raw
    foreach ($requiredField in @('RequireStableRenderer', 'fullyInitializedCheckpoint', 'processCountStable', 'changed renderer identity', 'target-route-loaded')) {
        if ($lifecycleSource -notmatch [regex]::Escape($requiredField)) {
            throw "Lifecycle attribution does not enforce $requiredField."
        }
    }
    $lifecycleSummarySource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Summarize-TrackBLifecycleAttribution.ps1') -Raw
    foreach ($requiredField in @('stateClass', 'fullyInitializedCheckpoint', 'rendererPidStable', 'processCountStable', 'acceptanceEligible', 'fullyInitializedRowCount', 'incompleteOrTransitionRowCount')) {
        if ($lifecycleSummarySource -notmatch [regex]::Escape($requiredField)) {
            throw "Lifecycle summary does not distinguish $requiredField."
        }
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
    $residentTypesSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Measure-TrackBResidentMemoryTypes.ps1') -Raw
    foreach ($requiredField in @('uniquePrivateResidentBytes', 'privateSharedFlagResidentBytes', 'QueryWorkingSetEx')) {
        if ($residentTypesSource -notmatch [regex]::Escape($requiredField)) {
            throw "Resident-memory classifier is missing $requiredField."
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
    foreach ($requiredField in @('imageNaturalPixelCount', 'animatedImageHintCount', 'playingVideoCount', 'videoReadyStateCounts', 'videoPixelCount', 'canvasPixelCount', 'nativeAllocationCategories', 'domCounters', 'routeFingerprint', 'routeClass', 'sampleStatus', 'available', 'reloadBeforeSampling', 'Page.reload')) {
        if ($cdpDiagnosticsSource -notmatch [regex]::Escape($requiredField)) {
            throw "CDP diagnostics do not report $requiredField."
        }
    }
    $traceSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Capture-TrackBCdpTrace.mjs') -Raw
    if ($traceSource -notmatch 'eventRatesPerSecond') {
        throw 'CDP trace does not normalize selected activity counts per second.'
    }
    foreach ($requiredField in @('redacted-url-or-path', 'No page text, paths, cookies, tokens, heap objects')) {
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
    $activeMatrixSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Test-TrackBActiveWorkloadMatrix.ps1') -Raw
    foreach ($requiredField in @('[switch] $Acceptance', 'functional status must be PASS in acceptance mode', 'private working set must be lower than OfficialDiscord', 'settled-idle private working-set median exceeds the 250 MiB target')) {
        if ($activeMatrixSource -notmatch [regex]::Escape($requiredField)) {
            throw "Active-workload acceptance gate is missing $requiredField."
        }
    }
    $activeMatrixSchemaSource = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $resolvedToolsPath) 'docs/benchmarks/track-b-active-workload-matrix-schema.json') -Raw
    foreach ($requiredField in @('mediaQuality', 'sourceResolutionComparable', 'rasterQualityComparable', 'visualQualityComparable')) {
        if ($activeMatrixSchemaSource -notmatch [regex]::Escape($requiredField)) {
            throw "Active-workload schema is missing $requiredField."
        }
    }
    foreach ($requiredField in @('mediaWorkloads', 'mediaQuality evidence is required in acceptance mode', 'hardwareAccelerationEnabled', 'sanitizedRouteFingerprint', 'sanitizedCallStateFingerprint', 'sameAccount', 'sameNetworkState')) {
        if ($activeMatrixSource -notmatch [regex]::Escape($requiredField)) {
            throw "Active-workload acceptance gate is missing $requiredField."
        }
    }
    foreach ($requiredField in @("ValidateSet('PASS', 'FAIL', 'UNTESTED')", '$FunctionalStatus = ''UNTESTED''', '$OperatorActionDurationSeconds', 'operatorAction', 'functionalStatus', 'durationSeconds')) {
        if ($featureCheckpointSource -notmatch [regex]::Escape($requiredField)) {
            throw "Feature scenario checkpoint does not preserve operator-qualified workload metadata: $requiredField"
        }
    }
    foreach ($requiredField in @('Get-RootIdentity', 'rootIdentity', 'rootIdentityStable', 'creationTime', 'executablePath', 'was not present in every workload sample', 'manualCheckpointConfirmedAt', 'comparisonContract')) {
        if ($featureCheckpointSource -notmatch [regex]::Escape($requiredField)) {
            throw "Feature scenario checkpoint does not preserve root-process identity validation: $requiredField."
        }
    }
    $activeWorkloadCheckpointTool = Join-Path $resolvedToolsPath 'Invoke-TrackBActiveWorkloadCheckpoint.ps1'
    if (-not (Test-Path -LiteralPath $activeWorkloadCheckpointTool -PathType Leaf)) {
        throw 'Active-workload checkpoint tool is missing.'
    }
    $activeWorkloadCheckpointSource = Get-Content -LiteralPath $activeWorkloadCheckpointTool -Raw
    foreach ($requiredField in @('Repetitions', 'RequireSettled', 'scenarioContract', 'READY', 'outputDirectories', 'noProductionFeatureReduction')) {
        if ($activeWorkloadCheckpointSource -notmatch [regex]::Escape($requiredField)) {
            throw "Active-workload checkpoint does not preserve $requiredField."
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
    $phase2MeasureSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Measure-DiscordPhase2Attribution.ps1') -Raw
    foreach ($requiredField in @('Convert-ProcessCreationTimeUtc', 'CreationDate', 'return $false')) {
        if ($phase2MeasureSource -notmatch [regex]::Escape($requiredField)) {
            throw "Phase 2 attribution does not validate process ancestry: $requiredField"
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
    foreach ($requiredField in @('privateWritableRegionCount', 'privateWritable4MiBTo16MiBResidentMiB', 'privateWritable16MiBOrLargerResidentMiB', 'functionalStatus', 'operatorActionDurationSeconds')) {
        if ($scenarioSummarySource -notmatch [regex]::Escape($requiredField)) {
            throw "Feature-scenario summary does not preserve $requiredField."
        }
    }
    $environmentProbeSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-DiscordEnvironmentProbe.mjs') -Raw
    foreach ($requiredField in @('allNativeGroupNames', 'discordNativeAllGroupShapes', 'Object.getOwnPropertyNames(native)')) {
        if ($environmentProbeSource -notmatch [regex]::Escape($requiredField)) {
            throw "Environment probe does not preserve complete native group enumeration: $requiredField"
        }
    }
    $preloadContractTool = Join-Path $resolvedToolsPath 'Extract-DiscordPreloadContract.mjs'
    if (-not (Test-Path -LiteralPath $preloadContractTool -PathType Leaf)) {
        throw 'Discord preload contract extractor is missing.'
    }
    $preloadContractSource = Get-Content -LiteralPath $preloadContractTool -Raw
    foreach ($requiredField in @('DiscordNative', 'IPCEvents', 'sourceBytes', 'account data', 'tokens')) {
        if ($preloadContractSource -notmatch [regex]::Escape($requiredField)) {
            throw "Discord preload contract extractor does not preserve $requiredField."
        }
    }
    $vanillaLauncherSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Launch-DiscordVanillaDiagnostic.ps1') -Raw
    foreach ($requiredField in @('--vanilla', '--multi-instance', '--start-inactive', '--user-data-dir=', '--remote-debugging-port=', 'does not stop', 'does not require an active process', 'discord_desktop_core-*', 'core.asar', 'Do not copy native modules')) {
        if ($vanillaLauncherSource -notmatch [regex]::Escape($requiredField)) {
            throw "Vanilla diagnostic launcher does not preserve $requiredField."
        }
    }
    $checkpointSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBMemoryAttributionCheckpoint.ps1') -Raw
    foreach ($requiredField in @('[string] $Scenario', "'-Scenario', `$Scenario")) {
        if ($checkpointSource -notmatch [regex]::Escape($requiredField)) {
            throw "Memory attribution checkpoint does not preserve a caller-supplied scenario label: $requiredField."
        }
    }
    $unverifiedAttributionSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBUnverifiedCurrentAttribution.ps1') -Raw
    foreach ($requiredField in @('$treeSamples = @($tree.samples)', 'Process attribution completed without samples', '$lastTreeSample')) {
        if ($unverifiedAttributionSource -notmatch [regex]::Escape($requiredField)) {
            throw "Unverified attribution wrapper does not validate its process-tree result: $requiredField"
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
        'Get-DescendantProcesses',
        'rendererPids',
        'rendererPidStable',
        'rendererPidSource',
        'final-process-tree-sample',
        'Measured renderer PID'
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
    foreach ($requiredField in @('same authenticated account', 'Type READY', 'track-b-canonical-authenticated-static', 'Repetitions', '$DurationSeconds = 600')) {
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
    $benchmarkCompareSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Compare-DiscordBenchmark.ps1') -Raw
    foreach ($requiredField in @('ComparisonManifest', 'pristineOfficialReference', 'routeKey', 'refreshHz', 'sameRouteWindowDisplayWorkload')) {
        if ($benchmarkCompareSource -notmatch [regex]::Escape($requiredField)) {
            throw "Official-versus-Track-B benchmark comparison does not preserve $requiredField."
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBEnvironmentProbe.ps1') -PathType Leaf)) {
        throw 'Track B environment probe wrapper is missing.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $resolvedToolsPath 'Test-TrackBDesktopIdentity.ps1') -PathType Leaf)) {
        throw 'Track B desktop identity validator is missing.'
    }
    $lifecycleCaptureSource = Get-Content -LiteralPath (Join-Path $resolvedToolsPath 'Invoke-TrackBAuthenticatedMediaLifecycle.ps1') -Raw
    foreach ($requiredField in @('canonical-static', 'media-heavy', 'returned-static', 'manualCheckpointConfirmedAt', 'rendererPid', 'sameRendererPid', 'authenticated-no-bridges', 'Measure-DiscordPhase2Attribution', 'Invoke-DiscordPhase2CdpDiagnostics.mjs')) {
        if ($lifecycleCaptureSource -notmatch [regex]::Escape($requiredField)) {
            throw "Authenticated media lifecycle capture does not preserve $requiredField."
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
        [pscustomobject]@{ id = $_; status = 'PASS'; notes = if ($_ -in @('images-media', 'voice', 'video', 'screen-share')) { 'synthetic functional evidence recorded' } else { 'synthetic checkpoint evidence recorded' } }
    }
    [pscustomobject]@{
        builds = @('KoroneDiscordShell')
        workingSetMiB = [pscustomobject]@{ median = 200; p95 = 220 }
        privateWorkingSetMiB = [pscustomobject]@{ median = 150; p95 = 245 }
        privateMemoryMiB = [pscustomobject]@{ median = 240; p95 = 245 }
        processCount = [pscustomobject]@{ median = 8; maximum = 8 }
        cpuPercentOfTotal = [pscustomobject]@{ medianRun = 0.1; p95Run = 0.15 }
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceCandidatePath -Encoding utf8
    [pscustomobject]@{ processName = 'KoroneDiscordShell'; windowResponding = $true; passed = $true; results = $functionalFixtureResults } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceFunctionalPath -Encoding utf8
    [pscustomobject]@{ parityReady = $true; visualReviewPassed = $true; screenshotComparison = [pscustomobject]@{ width = 1920; height = 1080; differingPixelPercent = 0; meanAbsoluteChannelError = 0; p95PixelError = 0 }; mediaQuality = [pscustomobject]@{ sourceResolutionComparable = $true; rasterQualityComparable = $true; hardwareAccelerationEnabled = $true; visualQualityComparable = $true }; mediaQualityProvenance = [pscustomobject]@{ comparisonTool = 'Compare-DiscordMediaQuality.mjs'; source = [pscustomobject]@{ official = 'official.json'; trackB = 'track-b.json' } } } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceVisualPath -Encoding utf8
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
    [pscustomobject]@{ processName = 'DiscordPTB'; windowResponding = $true; passed = $true; results = $functionalFixtureResults } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceFunctionalPath -Encoding utf8
    $wrongProcessText = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath
    $wrongProcessResult = $wrongProcessText | ConvertFrom-Json
    if ($wrongProcessResult.passed -or $wrongProcessResult.functionalProcessValid) {
        throw 'Acceptance gate must reject functional results attributed to the stock Discord process.'
    }
    [pscustomobject]@{ processName = 'KoroneDiscordShell'; windowResponding = $true; passed = $true; results = $functionalFixtureResults } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceFunctionalPath -Encoding utf8
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
    $desktopParityNativeSource = Get-Content -LiteralPath $desktopParityOracleLauncher -Raw
    foreach ($requiredField in @('ClientToScreen', 'GetWindowDpiAwarenessContext', 'GetMonitorInfo', 'EnumDisplaySettingsEx', 'refreshRateHz', 'clientOrigin', 'dpiAwareness', 'monitor')) {
        if ($desktopParityNativeSource -notmatch [regex]::Escape($requiredField)) {
            throw "Desktop parity oracle is missing $requiredField."
        }
    }
    $desktopParityPageSource = Get-Content -LiteralPath $desktopParityOracleTool -Raw
    foreach ($requiredField in @('visualViewportScale', 'zoomFactor: null', 'dpiAwarenessEqual', 'refreshRateEqual', 'monitorGeometryEqual', 'nonClient?.width', 'titlebarGeometryEqual')) {
        if ($desktopParityPageSource -notmatch [regex]::Escape($requiredField)) {
            throw "Desktop parity page probe is missing $requiredField."
        }
    }
    foreach ($powerMonitorTool in @($powerMonitorLauncher, $powerMonitorTestTool)) {
        if (-not (Test-Path -LiteralPath $powerMonitorTool -PathType Leaf)) {
            throw "Power-monitor capability test is missing: $powerMonitorTool"
        }
    }
    $powerMonitorSource = Get-Content -LiteralPath $powerMonitorLauncher -Raw
    foreach ($requiredField in @('--diagnostic-power-monitor', '9242', 'Test-TrackBPowerMonitor.mjs', 'normalShellRestoredPid')) {
        if ($powerMonitorSource -notmatch [regex]::Escape($requiredField)) {
            throw "Power-monitor launcher does not preserve $requiredField."
        }
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
