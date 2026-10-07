[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$tool = Join-Path $PSScriptRoot 'Summarize-TrackBCanonicalAllocationStability.ps1'
if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) { throw "Canonical allocation summarizer was not found: $tool" }

$root = Join-Path ([IO.Path]::GetTempPath()) ('track-b-canonical-allocation-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root -Force | Out-Null
try {
    function Write-Json {
        param([string] $Path, [object] $Value)
        $Value | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding utf8
    }

    foreach ($repeat in 1..3) {
        $directory = Join-Path $root ('repeat-{0:d2}' -f $repeat)
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        $largeResident = (100 - (($repeat - 1) * 10)) * 1MB
        Write-Json (Join-Path $directory 'renderer-resident-types.json') ([pscustomobject]@{
            processId = 321
            role = 'renderer'
            memory = [pscustomobject]@{ residentValidBytes = 180MB; privateWritableResidentBytes = (140 - (($repeat - 1) * 10)) * 1MB; committedPrivateWritableBytes = 200MB }
            allocationBaseGroups = @(
                [pscustomobject]@{ allocationBase = '0xPRIVATE-A'; residentBytes = $largeResident; committedBytes = 120MB; regionCount = 2 },
                [pscustomobject]@{ allocationBase = '0xPRIVATE-B'; residentBytes = 20MB; committedBytes = 30MB; regionCount = 1 }
            )
        })
        Write-Json (Join-Path $directory 'process-tree-summary.json') ([pscustomobject]@{
            processTree = [pscustomobject]@{ privateWorkingSetMedianMiB = 250 + $repeat; privateMemoryMedianMiB = 400 + $repeat }
            roles = @([pscustomobject]@{ role = 'renderer'; privateWorkingSetMedianMiB = 180 + $repeat; privateMemoryMedianMiB = 250 + $repeat })
        })
    }

    $output = Join-Path $root 'output.json'
    & (Get-Command powershell.exe).Source -NoProfile -File $tool -InputDirectory $root -TopN 2 -OutputPath $output | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Canonical allocation summarizer exited with code $LASTEXITCODE." }
    $result = Get-Content -Raw -LiteralPath $output | ConvertFrom-Json
    if ($result.repeatCount -ne 3 -or -not $result.sameRendererPidAcrossRepeats) { throw 'Repeat or renderer-PID stability was not preserved.' }
    if (@($result.allocationFamilies).Count -ne 2) { throw 'Family correlation did not preserve the two same-PID families.' }
    if ($result.repeats[0].processTreePrivateWorkingSetMedianMiB -ne 251 -or $result.repeats[0].rendererPrivateWorkingSetMedianMiB -ne 181) { throw 'Process-tree or renderer summary metrics were not preserved.' }
    $family = @($result.allocationFamilies | Where-Object { $_.observedRepeatCount -eq 3 } | Select-Object -First 1)[0]
    if ($null -eq $family -or $family.residentMinMiB -ne 80 -or $family.residentMaxMiB -ne 100) { throw 'Family resident statistics were incorrect.' }
    $serialized = Get-Content -Raw -LiteralPath $output
    foreach ($address in @('0xPRIVATE-A', '0xPRIVATE-B')) {
        if ($serialized.Contains($address)) { throw 'Raw allocation-base data leaked into sanitized output.' }
    }
    [pscustomobject]@{ result = 'PASS'; repeats = $result.repeatCount; families = @($result.allocationFamilies).Count; ranks = @($result.rankStability).Count }
}
finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
