[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ExecutablePath,

    [ValidateRange(5, 3600)]
    [int] $DurationSeconds = 60,

    [ValidateRange(1, 60)]
    [int] $IntervalSeconds = 5,

    [ValidateRange(1, 60)]
    [int] $CdpDurationSeconds = 10,

    [ValidateRange(1, 60)]
    [int] $StableProbeSeconds = 5,

    [ValidateRange(2, 30)]
    [int] $StableSamples = 6,

    [ValidateRange(0.1, 25)]
    [double] $MaxVariationPercent = 1,

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-authenticated-media-lifecycle-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

$ErrorActionPreference = 'Stop'
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath).Path
$measureTool = Join-Path $PSScriptRoot 'Measure-DiscordPhase2Attribution.ps1'
$residentTool = Join-Path $PSScriptRoot 'Measure-TrackBResidentMemoryTypes.ps1'
$settledTool = Join-Path $PSScriptRoot 'Invoke-TrackBSettledAttribution.ps1'
$cdpTool = Join-Path $PSScriptRoot 'Invoke-DiscordPhase2CdpDiagnostics.mjs'
foreach ($path in @($measureTool, $residentTool, $settledTool, $cdpTool)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required lifecycle tool was not found: $path" }
}

$existing = @(Get-Process -Name KoroneDiscordShell -ErrorAction SilentlyContinue)
if ($existing.Count -gt 0) {
    throw 'An existing Track B shell is running. Close it before starting the authenticated no-bridge lifecycle capture.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$node = (Get-Command node.exe -ErrorAction Stop).Source
$process = $null
$states = @(
    [pscustomobject]@{ name = 'canonical-static'; prompt = 'Leave the authenticated canonical static DM or text channel visible. No call, typing, scrolling, or visible media.' }
    [pscustomobject]@{ name = 'media-heavy'; prompt = 'Navigate to the authenticated media-heavy channel. Leave visible GIFs, stickers, images, or embeds in the viewport without changing account settings.' }
    [pscustomobject]@{ name = 'returned-static'; prompt = 'Return to the exact authenticated canonical static route used for the first checkpoint and leave it untouched.' }
)
$records = [System.Collections.Generic.List[object]]::new()
$rendererPid = $null

function Wait-Endpoint {
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri 'http://127.0.0.1:9230/json/list' -TimeoutSec 1)
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) { return }
        }
        catch { }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    throw 'Authenticated no-bridge CDP endpoint did not become ready on port 9230.'
}

function Get-RendererPidFromTree {
    param([string] $Path)
    $tree = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    $sample = $tree.samples[-1]
    $renderer = @($sample.processes | Where-Object { $_.role -eq 'renderer' } | Select-Object -First 1)[0]
    if (-not $renderer) { throw "No renderer was present in $Path." }
    [pscustomobject]@{
        pid = [int]$renderer.pid
        processCount = [int]$sample.processCount
        privateWorkingSetMiB = [double]$sample.summary.privateWorkingSetMiB
        privateBytesMiB = [double]$sample.summary.privateMemoryMiB
        cpuPercent = [double]$sample.summary.cpuPercentOfTotal
    }
}

try {
    $process = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-authenticated-no-bridges' -PassThru
    Wait-Endpoint
    foreach ($state in $states) {
        Write-Host $state.prompt
        $confirmation = Read-Host "Type READY for $($state.name)"
        if ($confirmation -cne 'READY') { throw "Manual checkpoint was not confirmed for $($state.name)." }
        $confirmedAt = (Get-Date).ToUniversalTime().ToString('o')
        $stateDirectory = Join-Path $OutputDirectory $state.name
        New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null
        $settledDirectory = Join-Path $stateDirectory 'settled'
        & powershell -NoProfile -ExecutionPolicy Bypass -File $settledTool `
            -RootPid $process.Id `
            -ProbeSeconds $StableProbeSeconds `
            -StableSamples $StableSamples `
            -MaxVariationPercent $MaxVariationPercent `
            -MeasurementSeconds $DurationSeconds `
            -MeasurementIntervalSeconds $IntervalSeconds `
            -Scenario "track-b-authenticated-$($state.name)" `
            -OutputDirectory $settledDirectory | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Stable settled capture failed for $($state.name)." }
        $treePath = Join-Path $settledDirectory 'measurement.json'
        $cdpPath = Join-Path $stateDirectory 'cdp.json'
        $identity = Get-RendererPidFromTree $treePath
        if ($null -eq $rendererPid) { $rendererPid = $identity.pid }
        if ($identity.pid -ne $rendererPid) { throw "Renderer PID changed at $($state.name): expected $rendererPid, observed $($identity.pid)." }
        $residentPath = Join-Path $stateDirectory 'renderer-resident-types.json'
        & $residentTool -ProcessId $identity.pid -Role renderer -OutputPath $residentPath | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Renderer resident classification failed for $($state.name)." }
        & $node $cdpTool 9230 $CdpDurationSeconds $cdpPath
        if ($LASTEXITCODE -ne 0) { throw "CDP aggregate capture failed for $($state.name)." }
        $records.Add([pscustomobject]@{
            state = $state.name
            manualCheckpointConfirmedAt = $confirmedAt
            rendererPid = $identity.pid
            processCount = $identity.processCount
            privateWorkingSetMiB = $identity.privateWorkingSetMiB
            privateBytesMiB = $identity.privateBytesMiB
            cpuPercent = $identity.cpuPercent
            processTreePath = (Resolve-Path -LiteralPath $treePath).Path
            settleResultPath = (Resolve-Path -LiteralPath (Join-Path $settledDirectory 'settle-result.json')).Path
            settledSummaryPath = (Resolve-Path -LiteralPath (Join-Path $settledDirectory 'measurement-summary.json')).Path
            rendererResidentPath = (Resolve-Path -LiteralPath $residentPath).Path
            cdpPath = (Resolve-Path -LiteralPath $cdpPath).Path
        })
    }
    if (@($records | Select-Object -ExpandProperty rendererPid -Unique).Count -ne 1) { throw 'The lifecycle did not preserve one renderer PID across all states.' }
    $allocationFamilies = foreach ($record in $records) {
        $resident = Get-Content -LiteralPath $record.rendererResidentPath -Raw | ConvertFrom-Json
        $rank = 0
        foreach ($family in @($resident.allocationBaseGroups | Sort-Object residentBytes -Descending | Select-Object -First 10)) {
            $rank++
            [pscustomobject]@{
                state = $record.state
                rank = $rank
                residentMiB = [double]$family.residentMiB
                committedMiB = [double]$family.committedMiB
                regionCount = [int]$family.regionCount
            }
        }
    }
    $allocationPath = Join-Path $OutputDirectory 'allocation-family-rank-comparison.json'
    [pscustomobject]@{
        schemaVersion = 1
        rendererPid = $rendererPid
        states = @($records | ForEach-Object { $_.state })
        rankingBasis = 'Resident private-writable allocation-base groups ranked separately within one renderer lifecycle; raw addresses intentionally omitted.'
        families = @($allocationFamilies)
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $allocationPath -Encoding utf8
    [pscustomobject]@{
        result = 'CAPTURED'
        scenario = 'track-b-authenticated-media-lifecycle'
        diagnosticMode = 'authenticated-no-bridges'
        sameRendererPid = $true
        rendererPid = $rendererPid
        states = @($records)
        allocationFamilyRankComparison = (Resolve-Path -LiteralPath $allocationPath).Path
        stability = [pscustomobject]@{
            probeSeconds = $StableProbeSeconds
            requiredSamples = $StableSamples
            maxVariationPercent = $MaxVariationPercent
        }
        policy = 'Manual READY checkpoints with per-PID process-tree, resident-memory, and aggregate CDP diagnostics. No route URLs, account content, command lines, tokens, or heap objects are written. Production behavior and official Discord are untouched.'
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'manifest.json') -Encoding utf8
    [pscustomobject]@{
        result = 'CAPTURED'
        outputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
        manifestPath = (Resolve-Path -LiteralPath (Join-Path $OutputDirectory 'manifest.json')).Path
        rendererPid = $rendererPid
        sameRendererPid = $true
    } | ConvertTo-Json -Depth 5
}
finally {
    if ($process) {
        $current = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
        if ($current) {
            [void]$current.CloseMainWindow()
            if (-not $current.WaitForExit(10000)) { throw "Track B diagnostic process $($process.Id) did not close normally." }
        }
    }
}
