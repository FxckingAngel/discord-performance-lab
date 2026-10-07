[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [ValidateSet('normal', 'below-normal', 'low', 'very-low')]
    [string] $Priority = 'low',

    [ValidateRange(5, 3600)]
    [int] $DurationSeconds = 30,

    [ValidateRange(1, 60)]
    [int] $IntervalSeconds = 5,

    [string[]] $ExcludeRole = @('gpu-process', 'utility/audio.mojom.AudioService'),

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB',

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory,

    [switch] $BackgroundIdleConfirmed
)

if (-not $BackgroundIdleConfirmed) {
    throw 'Refusing to change memory priority without -BackgroundIdleConfirmed. A minimized Discord window can still carry an active call or media session.'
}

$scriptDirectory = Split-Path -Parent $PSCommandPath
$setPriorityScript = Join-Path $scriptDirectory 'Set-DiscordProcessMemoryPriority.ps1'
$getPriorityScript = Join-Path $scriptDirectory 'Get-DiscordProcessMemoryPriority.ps1'
$measureScript = Join-Path $scriptDirectory 'Measure-DiscordProcessTree.ps1'
foreach ($requiredScript in @($setPriorityScript, $getPriorityScript, $measureScript)) {
    if (-not (Test-Path -LiteralPath $requiredScript -PathType Leaf)) {
        throw "Required tool was not found: $requiredScript"
    }
}

$resolvedOutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $resolvedOutputDirectory -Force | Out-Null
$stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$experimentDirectory = Join-Path $resolvedOutputDirectory "memory-priority-$stamp"
New-Item -ItemType Directory -Path $experimentDirectory -Force | Out-Null

function Get-MemoryPriorityState {
    param([string] $OutputPath)

    $stateText = & $getPriorityScript -RootPid $RootPid -ProcessName $ProcessName | Out-String
    if ([string]::IsNullOrWhiteSpace($stateText)) {
        throw "Could not read memory priority for root PID $RootPid."
    }
    $stateText | Set-Content -LiteralPath $OutputPath -Encoding utf8
    $state = @($stateText | ConvertFrom-Json)
    if (@($state | Where-Object status -eq 'failed').Count -gt 0) {
        throw "Could not read memory priority for root PID $RootPid."
    }
    return $state
}

function Set-MemoryPriority {
    param(
        [string] $TargetPriority,
        [string[]] $ExcludedRoles
    )

    $outputText = & $setPriorityScript -RootPid $RootPid -Priority $TargetPriority -ExcludeRole $ExcludedRoles -ProcessName $ProcessName | Out-String
    if ([string]::IsNullOrWhiteSpace($outputText)) {
        throw "Could not set memory priority to $TargetPriority for root PID $RootPid."
    }
    $output = @($outputText | ConvertFrom-Json)
    if (@($output | Where-Object status -eq 'failed').Count -gt 0) {
        throw "Could not set memory priority to $TargetPriority for root PID $RootPid."
    }
    return $output
}

function Measure-Tree {
    param([string] $Scenario, [string] $OutputPath)

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        & $measureScript -ProcessName $ProcessName -RootPid $RootPid -DurationSeconds $DurationSeconds -IntervalSeconds $IntervalSeconds -Scenario $Scenario -OutputPath $OutputPath | Out-Null
    }
    catch {
        throw "Measurement failed for scenario ${Scenario}: $($_.Exception.Message)"
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if (-not (Test-Path -LiteralPath $OutputPath -PathType Leaf)) {
        throw "Measurement failed for scenario $Scenario."
    }
}

$beforeStatePath = Join-Path $experimentDirectory 'before-state.json'
$stockMeasurementPath = Join-Path $experimentDirectory 'stock.json'
$candidateStatePath = Join-Path $experimentDirectory 'candidate-state.json'
$candidateMeasurementPath = Join-Path $experimentDirectory 'candidate.json'
$rollbackStatePath = Join-Path $experimentDirectory 'rollback-state.json'
$manifestPath = Join-Path $experimentDirectory 'manifest.json'
$rollbackSucceeded = $false

try {
    $beforeState = Get-MemoryPriorityState -OutputPath $beforeStatePath
    $unexpected = @($beforeState | Where-Object { $_.priority -ne 'normal' })
    if ($unexpected.Count -gt 0) {
        throw 'Refusing to start because the rooted tree did not begin with normal memory priority.'
    }

    Measure-Tree -Scenario 'memory-priority-stock' -OutputPath $stockMeasurementPath
    [void] (Set-MemoryPriority -TargetPriority $Priority -ExcludedRoles $ExcludeRole)
    $candidateState = Get-MemoryPriorityState -OutputPath $candidateStatePath
    Measure-Tree -Scenario "memory-priority-$Priority" -OutputPath $candidateMeasurementPath
}
finally {
    try {
        [void] (Set-MemoryPriority -TargetPriority 'normal' -ExcludedRoles @())
        $rollbackState = Get-MemoryPriorityState -OutputPath $rollbackStatePath
        $rollbackSucceeded = @($rollbackState | Where-Object { $_.priority -ne 'normal' }).Count -eq 0
    }
    catch {
        $rollbackSucceeded = $false
        $_ | Out-String | Set-Content -LiteralPath (Join-Path $experimentDirectory 'rollback-error.txt') -Encoding utf8
    }
}

$manifest = [pscustomobject]@{
    schemaVersion = 1
    processName = $ProcessName
    rootPid = $RootPid
    priority = $Priority
    excludedRoles = @($ExcludeRole)
    durationSeconds = $DurationSeconds
    intervalSeconds = $IntervalSeconds
    backgroundIdleConfirmed = [bool] $BackgroundIdleConfirmed
    rollbackSucceeded = $rollbackSucceeded
    stockMeasurement = $stockMeasurementPath
    candidateMeasurement = $candidateMeasurementPath
    beforeState = $beforeStatePath
    candidateState = $candidateStatePath
    rollbackState = $rollbackStatePath
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
$manifest

if (-not $rollbackSucceeded) {
    throw 'The experiment completed without proving that normal memory priority was restored.'
}
