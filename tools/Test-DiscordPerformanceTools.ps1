[CmdletBinding()]
param(
    [string] $ToolsPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'tools')
)

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
$compareTool = Join-Path $resolvedToolsPath 'Compare-DiscordBenchmark.ps1'
$measureTool = Join-Path $resolvedToolsPath 'Measure-DiscordProcessTree.ps1'
$joinTool = Join-Path $resolvedToolsPath 'Join-TrackBCdpWindowsAttribution.ps1'
$traceCompareTool = Join-Path $resolvedToolsPath 'Compare-TrackBCdpTrace.ps1'
$functionalCheckpointTool = Join-Path $resolvedToolsPath 'Invoke-TrackBFunctionalCheckpoint.ps1'
$visualCheckpointTool = Join-Path $resolvedToolsPath 'Invoke-TrackBVisualCheckpoint.ps1'
$acceptanceGateTool = Join-Path $resolvedToolsPath 'Test-TrackBAcceptance.ps1'
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
    if (-not (Test-Path -LiteralPath $acceptanceGateTool -PathType Leaf)) {
        throw 'Track B acceptance gate tool is missing.'
    }
    $acceptanceGateSource = Get-Content -LiteralPath $acceptanceGateTool -Raw
    foreach ($requiredField in @('privateWorkingSetMiB', 'privateMemoryMiB', 'cpuPercentOfTotal', 'functionalPassed', 'visualPassed')) {
        if ($acceptanceGateSource -notmatch [regex]::Escape($requiredField)) {
            throw "Track B acceptance gate does not evaluate $requiredField."
        }
    }
    $shellSource = Get-Content -LiteralPath $shellSourcePath -Raw
    if ($shellSource -notmatch 'Uri\.TryCreate') {
        throw 'Normal bridge origin validation does not parse the message source as a URI.'
    }
    if ($shellSource -notmatch 'UriSchemeHttps') {
        throw 'Normal bridge origin validation does not require HTTPS.'
    }
    if ($shellSource -notmatch '\.discord\.com') {
        throw 'Normal bridge origin validation does not enforce the Discord host boundary.'
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
    [pscustomobject]@{
        privateWorkingSetMiB = [pscustomobject]@{ median = 150 }
        privateMemoryMiB = [pscustomobject]@{ median = 240 }
        cpuPercentOfTotal = [pscustomobject]@{ medianRun = 0.1; p95Run = 0.15 }
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceCandidatePath -Encoding utf8
    [pscustomobject]@{ passed = $true; results = @([pscustomobject]@{ status = 'PASS' }) } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceFunctionalPath -Encoding utf8
    [pscustomobject]@{ parityReady = $true; visualReviewPassed = $true; screenshotComparison = [pscustomobject]@{ differingPixelPercent = 0 } } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceVisualPath -Encoding utf8
    $acceptanceResultText = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath -OutputPath $acceptanceOutputPath
    $acceptanceResult = $acceptanceResultText | ConvertFrom-Json
    if (-not $acceptanceResult.passed) {
        throw "Synthetic Track B acceptance gate should pass when every gate is satisfied: $($acceptanceResult | ConvertTo-Json -Compress)"
    }
    [pscustomobject]@{ parityReady = $true; visualReviewPassed = $false; screenshotComparison = [pscustomobject]@{ differingPixelPercent = 0 } } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $acceptanceVisualPath -Encoding utf8
    $rejectedAcceptanceText = & $acceptanceGateTool -CandidateSummary $acceptanceCandidatePath -FunctionalReport $acceptanceFunctionalPath -VisualReport $acceptanceVisualPath
    $rejectedAcceptanceResult = $rejectedAcceptanceText | ConvertFrom-Json
    if ($rejectedAcceptanceResult.passed) {
        throw 'Synthetic Track B acceptance gate should fail without explicit visual review.'
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
