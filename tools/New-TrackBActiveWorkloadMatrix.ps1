[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-active-workload-matrix-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

$ErrorActionPreference = 'Stop'

$workloads = @(
    [pscustomobject]@{ id = 'settled-idle'; label = 'Settled idle'; actionRequired = $false; manualPreparation = 'Fully initialized static DM or text channel; leave untouched after settling.'; notes = 'Idle target applies here.' }
    [pscustomobject]@{ id = 'active-text'; label = 'Active text/chat'; actionRequired = $true; manualPreparation = 'Navigate, type, send, edit or react to a test message, and verify the result.'; notes = 'Do not record message content.' }
    [pscustomobject]@{ id = 'channel-navigation'; label = 'Channel navigation'; actionRequired = $true; manualPreparation = 'Navigate through the predetermined channel/DM sequence and return to the final route.'; notes = 'Use the same sequence for both builds.' }
    [pscustomobject]@{ id = 'scrolling'; label = 'History scrolling'; actionRequired = $true; manualPreparation = 'Scroll the same history range at a repeatable pace, then settle.'; notes = 'Record the action duration.' }
    [pscustomobject]@{ id = 'media-heavy'; label = 'Media-heavy channel'; actionRequired = $true; manualPreparation = 'Keep visible GIFs, stickers, images, and embeds enabled and visible; verify normal quality.'; notes = 'No media disabling or quality reduction is allowed.' }
    [pscustomobject]@{ id = 'voice-idle'; label = 'Voice connected, quiet'; actionRequired = $true; manualPreparation = 'Connect to voice with nobody speaking; verify audio controls and chat remain usable.'; notes = 'Do not change the official control.' }
    [pscustomobject]@{ id = 'active-voice'; label = 'Active voice'; actionRequired = $true; manualPreparation = 'Use normal microphone input and incoming speech; verify intelligibility and responsiveness.'; notes = 'Record only sanitized functional notes.' }
    [pscustomobject]@{ id = 'video'; label = 'Video call'; actionRequired = $true; manualPreparation = 'Use the same camera/call state and verify device controls, frame stability, and latency.'; notes = 'Compare against the same call state.' }
    [pscustomobject]@{ id = 'screen-sharing'; label = 'Screen sharing'; actionRequired = $true; manualPreparation = 'Share the same window or display and verify capture quality, controls, encoder behavior, and latency.'; notes = 'Do not compare directly with idle.' }
    [pscustomobject]@{ id = 'notifications'; label = 'Notifications'; actionRequired = $true; manualPreparation = 'Receive and open a normal notification; record only sanitized status and timing.'; notes = 'No message content or private identifiers.' }
    [pscustomobject]@{ id = 'gaming-background'; label = 'Gaming with Discord in background'; actionRequired = $true; manualPreparation = 'Use the same game and Discord background state; record responsiveness and resource impact.'; notes = 'Do not change game settings for the comparison.' }
) | ForEach-Object {
    [pscustomobject]@{
        id = $_.id
        label = $_.label
        actionRequired = $_.actionRequired
        manualPreparation = $_.manualPreparation
        sameStateAcrossBuilds = $true
        notes = $_.notes
    }
}

$requiredMetrics = @(
    'completeTreePrivateWorkingSetMiB',
    'completeTreeWorkingSetMiB',
    'completeTreePrivateBytesMiB',
    'completeTreeCpuMedianPercent',
    'completeTreeCpuP95Percent',
    'gpuUsage',
    'gpuMemoryMiB',
    'processCount',
    'responsiveness',
    'functionalStatus'
)

$result = [ordered]@{
    schemaVersion = 1
    matrixId = 'track-b-active-workload-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
    createdAt = (Get-Date).ToUniversalTime().ToString('o')
    schema = 'docs/benchmarks/track-b-active-workload-matrix-schema.json'
    controlPolicy = [ordered]@{
        officialMode = 'read-only-stock-reference'
        officialRestartAllowed = $false
        trackBRestartAllowed = $true
        rawArtifactsPrivate = $true
        sameMachineRequired = $true
    }
    requiredMetrics = $requiredMetrics
    comparisonConditions = [ordered]@{
        sameAccount = $true
        sameRoute = $true
        sameCallState = $true
        sameWindowDimensions = $true
        sameDisplay = $true
        sameDisplayScaling = $true
        sameNetworkState = $true
        sameDuration = $true
    }
    workloads = @($workloads)
    comparisonRecords = @()
    policy = 'Plan only. Does not launch, stop, restart, patch, inject into, or reconfigure either Discord client.'
}

$parent = Split-Path -Parent $OutputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8

[pscustomobject]@{
    result = 'PASS'
    matrixId = $result.matrixId
    workloadCount = @($workloads).Count
    outputPath = (Resolve-Path -LiteralPath $OutputPath).Path
    officialTouched = $false
    trackBStarted = $false
} | ConvertTo-Json -Depth 4
