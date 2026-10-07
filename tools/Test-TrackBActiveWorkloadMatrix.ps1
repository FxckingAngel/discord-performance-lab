[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $InputPath,

    [switch] $Acceptance,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
$matrix = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json

if ([int] $matrix.schemaVersion -ne 1) { throw 'Unsupported active-workload matrix schema version.' }
if ($matrix.controlPolicy.officialMode -ne 'read-only-stock-reference') { throw 'Official control is not marked read-only.' }
if ($matrix.controlPolicy.officialRestartAllowed -ne $false) { throw 'The matrix allows an unsafe official Discord restart.' }
if ($matrix.controlPolicy.rawArtifactsPrivate -ne $true) { throw 'Raw artifacts must remain private.' }

$requiredWorkloads = @('settled-idle', 'active-text', 'channel-navigation', 'scrolling', 'media-heavy', 'voice-idle', 'active-voice', 'video', 'screen-sharing', 'notifications', 'gaming-background')
$mediaWorkloads = @('media-heavy', 'video', 'screen-sharing')
$callWorkloads = @('voice-idle', 'active-voice', 'video', 'screen-sharing')
$declaredWorkloads = @($matrix.workloads | ForEach-Object { [string] $_.id })
$missingWorkloads = @($requiredWorkloads | Where-Object { $_ -notin $declaredWorkloads })
if ($missingWorkloads.Count -gt 0) { throw "Matrix is missing workloads: $($missingWorkloads -join ', ')." }

$records = @($matrix.comparisonRecords)
$errors = [System.Collections.Generic.List[string]]::new()
foreach ($workloadId in $requiredWorkloads) {
    foreach ($build in @('OfficialDiscord', 'TrackB')) {
        $matches = @($records | Where-Object { $_.workloadId -eq $workloadId -and $_.build -eq $build })
        if ($matches.Count -ne 1) {
            $errors.Add("Expected one $build record for $workloadId; found $($matches.Count).")
            continue
        }
        $record = $matches[0]
        foreach ($property in @('manualCheckpoint', 'frontendInitialized', 'routeStable', 'processInventorySynchronized', 'windowResponsive')) {
            if ($record.readiness.$property -ne $true) { $errors.Add("$build/$workloadId readiness.$property must be true.") }
        }
        foreach ($property in @('sameMachine', 'sameDisplay')) {
            if ($record.environment.$property -ne $true) { $errors.Add("$build/$workloadId environment.$property must be true.") }
        }
        foreach ($property in @('windowDimensions', 'displayRefreshRateHz')) {
            if ([string]::IsNullOrWhiteSpace([string]$record.environment.$property)) { $errors.Add("$build/$workloadId environment.$property is required.") }
        }
        if ($null -eq $record.environment.displayScalingPercent -or [double]$record.environment.displayScalingPercent -le 0) {
            $errors.Add("$build/$workloadId environment.displayScalingPercent must be positive.")
        }
        foreach ($property in @('completeTreePrivateWorkingSetMiB', 'completeTreeWorkingSetMiB', 'completeTreePrivateBytesMiB')) {
            if ($null -eq $record.metrics.$property.median -or $null -eq $record.metrics.$property.p95) { $errors.Add("$build/$workloadId is missing $property median/p95.") }
        }
        foreach ($property in @('completeTreeCpuMedianPercent', 'completeTreeCpuP95Percent', 'gpuUsage', 'gpuMemoryMiB', 'processCount', 'responsiveness')) {
            if ($null -eq $record.metrics.$property) { $errors.Add("$build/$workloadId is missing metrics.$property.") }
        }
        if ($record.metrics.responsiveness -eq 'UNTESTED') { $errors.Add("$build/$workloadId responsiveness is UNTESTED.") }
        if ($null -eq $record.action.status -or $null -eq $record.action.durationSeconds) { $errors.Add("$build/$workloadId is missing action status/duration.") }
        if ($null -eq $record.functional.status) { $errors.Add("$build/$workloadId is missing functional status.") }
        if ($record.functional.status -notin @('PASS', 'FAIL', 'UNTESTED')) { $errors.Add("$build/$workloadId has an invalid functional status.") }
        $workload = @($matrix.workloads | Where-Object id -eq $workloadId)[0]
        if ($workload.actionRequired -eq $true -and $record.action.status -eq 'UNTESTED') { $errors.Add("$build/$workloadId requires an exercised action.") }
    }
    $officialRecord = @($records | Where-Object { $_.workloadId -eq $workloadId -and $_.build -eq 'OfficialDiscord' })[0]
    $trackBRecord = @($records | Where-Object { $_.workloadId -eq $workloadId -and $_.build -eq 'TrackB' })[0]
    if ($officialRecord -and $trackBRecord) {
        foreach ($property in @('windowDimensions', 'displayRefreshRateHz', 'displayScalingPercent')) {
            if ([string]$officialRecord.environment.$property -ne [string]$trackBRecord.environment.$property) {
                $errors.Add("$workloadId official and TrackB environment.$property must match.")
            }
        }
        if ($Acceptance) {
            foreach ($buildRecord in @($officialRecord, $trackBRecord)) {
                foreach ($property in @('sameAccount', 'sameNetworkState')) {
                    if ($buildRecord.environment.$property -ne $true) {
                        $errors.Add("$($buildRecord.build)/$workloadId environment.$property must be true in acceptance mode.")
                    }
                }
                if ([string]::IsNullOrWhiteSpace([string]$buildRecord.environment.sanitizedRouteFingerprint)) {
                    $errors.Add("$($buildRecord.build)/$workloadId sanitizedRouteFingerprint is required in acceptance mode.")
                }
                if ($workloadId -in $callWorkloads -and [string]::IsNullOrWhiteSpace([string]$buildRecord.environment.sanitizedCallStateFingerprint)) {
                    $errors.Add("$($buildRecord.build)/$workloadId sanitizedCallStateFingerprint is required in acceptance mode.")
                }
            }
            foreach ($buildRecord in @($officialRecord, $trackBRecord)) {
                if ($buildRecord.functional.status -ne 'PASS') {
                    $errors.Add("$($buildRecord.build)/$workloadId functional status must be PASS in acceptance mode.")
                }
                if ($buildRecord.metrics.responsiveness -ne 'RESPONSIVE') {
                    $errors.Add("$($buildRecord.build)/$workloadId responsiveness must be RESPONSIVE in acceptance mode.")
                }
                if ($workload.actionRequired -eq $true -and $buildRecord.action.status -ne 'PASS') {
                    $errors.Add("$($buildRecord.build)/$workloadId action status must be PASS in acceptance mode.")
                }
            }
            if ([double]$trackBRecord.metrics.completeTreePrivateWorkingSetMiB.median -ge [double]$officialRecord.metrics.completeTreePrivateWorkingSetMiB.median) {
                $errors.Add("TrackB/$workloadId private working set must be lower than OfficialDiscord in acceptance mode.")
            }
            if ([double]$trackBRecord.metrics.completeTreeCpuMedianPercent -gt [double]$officialRecord.metrics.completeTreeCpuMedianPercent) {
                $errors.Add("TrackB/$workloadId median CPU must not exceed OfficialDiscord in acceptance mode.")
            }
            foreach ($property in @('sameAccount', 'sameNetworkState', 'sanitizedRouteFingerprint')) {
                if ([string]$officialRecord.environment.$property -ne [string]$trackBRecord.environment.$property) {
                    $errors.Add("$workloadId official and TrackB environment.$property must match in acceptance mode.")
                }
            }
            if ($workloadId -in $callWorkloads -and [string]$officialRecord.environment.sanitizedCallStateFingerprint -ne [string]$trackBRecord.environment.sanitizedCallStateFingerprint) {
                $errors.Add("$workloadId official and TrackB sanitizedCallStateFingerprint must match in acceptance mode.")
            }
            if ($workloadId -eq 'settled-idle') {
                if ([double]$trackBRecord.metrics.completeTreePrivateWorkingSetMiB.median -gt 250) {
                    $errors.Add('TrackB/settled-idle private working-set median exceeds the 250 MiB target.')
                }
                if ([double]$trackBRecord.metrics.completeTreeCpuMedianPercent -gt 0.2) {
                    $errors.Add('TrackB/settled-idle median CPU exceeds the 0.2% target.')
                }
            }
            if ($workloadId -in $mediaWorkloads) {
                $mediaQuality = $trackBRecord.mediaQuality
                if ($null -eq $mediaQuality) {
                    $errors.Add("TrackB/$workloadId mediaQuality evidence is required in acceptance mode.")
                } else {
                    foreach ($property in @('sourceResolutionComparable', 'rasterQualityComparable', 'hardwareAccelerationEnabled', 'visualQualityComparable')) {
                        if ($mediaQuality.$property -ne $true) {
                            $errors.Add("TrackB/$workloadId mediaQuality.$property must be true in acceptance mode.")
                        }
                    }
                }
            }
        }
    }
}

$result = [ordered]@{
    schemaVersion = 1
    validatedAt = (Get-Date).ToUniversalTime().ToString('o')
    inputPath = (Resolve-Path -LiteralPath $InputPath).Path
    passed = $errors.Count -eq 0
    requiredWorkloadCount = $requiredWorkloads.Count
    recordCount = $records.Count
    acceptanceMode = [bool]$Acceptance
    mediaQualityWorkloadCount = $mediaWorkloads.Count
    errors = @($errors)
    policy = 'Validation only. No client was launched, stopped, restarted, patched, injected, or reconfigured.'
}

if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
}
$result | ConvertTo-Json -Depth 8
if (-not $result.passed) { exit 1 }
