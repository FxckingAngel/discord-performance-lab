[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$tool = Join-Path $PSScriptRoot 'Summarize-TrackBLifecycleAllocationDeltas.ps1'
if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) { throw "Lifecycle allocation summarizer was not found: $tool" }

$root = Join-Path ([IO.Path]::GetTempPath()) ('track-b-lifecycle-summary-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root -Force | Out-Null
try {
    function Write-Json {
        param([string] $Path, [object] $Value)
        $Value | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding utf8
    }

    $memoryA = Join-Path $root 'memory-a.json'
    $memoryB = Join-Path $root 'memory-b.json'
    $memoryC = Join-Path $root 'memory-c.json'
    Write-Json $memoryA ([pscustomobject]@{
        processId = 101
        role = 'renderer'
        memory = [pscustomobject]@{ privateWritableResidentBytes = 120MB; committedPrivateWritableBytes = 180MB }
        allocationBaseGroups = @(
            [pscustomobject]@{ allocationBase = '0xSECRET-A'; residentBytes = 80MB; committedBytes = 100MB; regionCount = 2 },
            [pscustomobject]@{ allocationBase = '0xSECRET-B'; residentBytes = 20MB; committedBytes = 40MB; regionCount = 1 }
        )
    })
    Write-Json $memoryB ([pscustomobject]@{
        processId = 101
        role = 'renderer'
        memory = [pscustomobject]@{ privateWritableResidentBytes = 150MB; committedPrivateWritableBytes = 200MB }
        allocationBaseGroups = @(
            [pscustomobject]@{ allocationBase = '0xSECRET-A'; residentBytes = 90MB; committedBytes = 110MB; regionCount = 2 },
            [pscustomobject]@{ allocationBase = '0xSECRET-B'; residentBytes = 10MB; committedBytes = 40MB; regionCount = 1 }
        )
    })
    Write-Json $memoryC ([pscustomobject]@{
        processId = 202
        role = 'renderer'
        memory = [pscustomobject]@{ privateWritableResidentBytes = 70MB; committedPrivateWritableBytes = 90MB }
        allocationBaseGroups = @(
            [pscustomobject]@{ allocationBase = '0xSECRET-A'; residentBytes = 50MB; committedBytes = 60MB; regionCount = 1 }
        )
    })

    $summaryA = Join-Path $root 'summary-a.json'
    $summaryB = Join-Path $root 'summary-b.json'
    $summaryC = Join-Path $root 'summary-c.json'
    foreach ($path in @($summaryA, $summaryB, $summaryC)) {
        Write-Json $path ([pscustomobject]@{ roles = @([pscustomobject]@{ role = 'renderer'; privateWorkingSetMedianMiB = 100; privateMemoryMedianMiB = 120 }) })
    }

    $manifest = Join-Path $root 'manifest.json'
    Write-Json $manifest ([pscustomobject]@{
        checkpoints = @(
            [pscustomobject]@{ label = 'first'; rendererPid = 101; rendererPidStable = $true; processCountStable = $true; processCount = 3; fullyInitializedCheckpoint = $false; rendererMemoryTypesPath = $memoryA; processSummaryPath = $summaryA },
            [pscustomobject]@{ label = 'second'; rendererPid = 101; rendererPidStable = $true; processCountStable = $true; processCount = 3; fullyInitializedCheckpoint = $true; rendererMemoryTypesPath = $memoryB; processSummaryPath = $summaryB },
            [pscustomobject]@{ label = 'new-renderer'; rendererPid = 202; rendererPidStable = $true; processCountStable = $true; processCount = 3; fullyInitializedCheckpoint = $true; rendererMemoryTypesPath = $memoryC; processSummaryPath = $summaryC }
        )
    })
    $output = Join-Path $root 'output.json'
    & (Get-Command powershell.exe).Source -NoProfile -File $tool -ManifestPath $manifest -OutputPath $output -TopN 2 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Lifecycle allocation summarizer exited with code $LASTEXITCODE." }

    $result = Get-Content -Raw -LiteralPath $output | ConvertFrom-Json
    if ($result.checkpointCount -ne 3) { throw 'Checkpoint count was not preserved.' }
    if ($result.rendererInstanceCount -ne 2) { throw 'Renderer PID transitions were not split into separate instances.' }
    if (@($result.allocationFamilies).Count -ne 3) { throw 'Allocation families were not correlated within renderer instances.' }
    $samePidFamily = @($result.allocationFamilies | Where-Object { $_.firstCheckpoint -eq 'first' })[0]
    if ($null -eq $samePidFamily -or $samePidFamily.lastCheckpoint -ne 'second' -or $samePidFamily.deltaFirstToLastMiB -ne 10) {
        throw 'Same-PID allocation family lifecycle delta was incorrect.'
    }
    $serialized = Get-Content -Raw -LiteralPath $output
    foreach ($address in @('0xSECRET-A', '0xSECRET-B')) {
        if ($serialized.Contains($address)) { throw 'Raw allocation-base data leaked into sanitized output.' }
    }
    [pscustomobject]@{ result = 'PASS'; checkpoints = $result.checkpointCount; rendererInstances = $result.rendererInstanceCount; allocationFamilies = @($result.allocationFamilies).Count }
}
finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
