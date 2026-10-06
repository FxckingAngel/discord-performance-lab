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
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('discord-performance-lab-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
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
    if ($null -eq $summaryObject.roleBreakdown.renderer -or $summaryObject.roleBreakdown.renderer.cpuPercentOfTotal.median -le 0) {
        throw "Role-level CPU attribution was not calculated as expected."
    }
    $comparison = & $compareTool -BaselineSummary $baselineSummary -CandidateSummary $candidateSummary -OutputPath $comparisonPath | ConvertFrom-Json
    if (-not $comparison.passed) {
        throw 'Synthetic benchmark comparison did not pass.'
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
