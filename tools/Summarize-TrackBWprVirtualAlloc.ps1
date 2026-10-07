[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $InputPath,

    [Parameter(Mandatory = $true)]
    [string] $OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$lines = @(Get-Content -LiteralPath $InputPath)
$text = [string]::Join("`n", $lines)
$processMatch = [regex]::Match($text, 'Results for process [^\r\n]+\((\d+)\)')
$processId = if ($processMatch.Success) { [int]$processMatch.Groups[1].Value } else { $null }

$categoryRules = @(
    @{ name = 'chromium-partitionalloc'; pattern = '(?i)partition_alloc' },
    @{ name = 'v8-jit-code'; pattern = '(?i)v8::internal|Builtins_|JIT|CodeCreate' },
    @{ name = 'blink'; pattern = '(?i)blink::|DOMTimer|Layout|Style' },
    @{ name = 'skia-raster-image'; pattern = '(?i)skia|raster|image' },
    @{ name = 'media-webrtc'; pattern = '(?i)webrtc|audio|video|ffmpeg' },
    @{ name = 'discord-frontend'; pattern = '(?i)discord\.com/assets|discord frontend' }
)

function Get-Category([string] $Block) {
    foreach ($rule in $categoryRules) {
        if ($Block -match $rule.pattern) { return $rule.name }
    }
    return 'unresolved'
}

$blocks = [regex]::Matches($text, '(?ms)^---------------------------------------------------------------------\s*(.*?)(?=^---------------------------------------------------------------------|\z)')
$rows = foreach ($block in $blocks) {
    $body = [string]$block.Groups[1].Value
    # Skip GLOBAL ALLOCATIONS and TOP-N rollup blocks; retain only blocks with
    # an actual allocation stack so aggregate totals are not double-counted.
    if ($body -notmatch '(?m)^[A-Za-z0-9_.`''<>-]+\.dll!') { continue }
    $outstandingMatch = [regex]::Match($body, 'Outstanding committed\s*:\s*([0-9.]+)\s*KB')
    $committedMatch = [regex]::Match($body, '^Committed\s*:\s*([0-9.]+)\s*KB', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if (-not $outstandingMatch.Success) { continue }
    $outstandingKiB = [double]$outstandingMatch.Groups[1].Value
    $committedKiB = if ($committedMatch.Success) { [double]$committedMatch.Groups[1].Value } else { 0 }
    if ($outstandingKiB -le 0) { continue }
    [pscustomobject]@{
        category = Get-Category $body
        outstandingBytes = [int64]($outstandingKiB * 1024)
        committedBytes = [int64]($committedKiB * 1024)
    }
}

$families = foreach ($group in ($rows | Group-Object category)) {
    $outstanding = [int64](($group.Group | Measure-Object outstandingBytes -Sum).Sum)
    $committed = [int64](($group.Group | Measure-Object committedBytes -Sum).Sum)
    [pscustomobject]@{
        category = $group.Name
        blockCount = $group.Count
        outstandingBytes = $outstanding
        outstandingMiB = [math]::Round(($outstanding / 1MB), 6)
        committedBytes = $committed
        committedMiB = [math]::Round(($committed / 1MB), 6)
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    summarizedAt = (Get-Date).ToUniversalTime().ToString('o')
    source = (Resolve-Path -LiteralPath $InputPath).Path
    processId = $processId
    rawOutputRetainedPrivate = $true
    blockCount = @($rows).Count
    outstandingBytes = [int64](($rows | Measure-Object outstandingBytes -Sum).Sum)
    outstandingMiB = [math]::Round((([double](($rows | Measure-Object outstandingBytes -Sum).Sum)) / 1MB), 6)
    families = @($families | Sort-Object outstandingBytes -Descending)
    limitation = 'Categories are inferred from sanitized stack-pattern matches. This is virtual-allocation commit evidence, not total private working-set ownership or unique resident physical memory.'
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
