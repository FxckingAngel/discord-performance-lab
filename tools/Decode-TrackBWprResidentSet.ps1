[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ResidentSetXmlPath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ProcessTreeManifestPath,

    [Parameter(Mandatory = $true)]
    [string] $OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$pageSize = 4096

$xml = [xml](Get-Content -LiteralPath $ResidentSetXmlPath -Raw)
$manifest = @(Get-Content -LiteralPath $ProcessTreeManifestPath -Raw | ConvertFrom-Json)
$manifestByPid = @{}
foreach ($entry in $manifest) {
    $manifestByPid[[int]$entry.ProcessId] = [pscustomobject]@{
        pid = [int]$entry.ProcessId
        parentPid = [int]$entry.ParentProcessId
        name = [string]$entry.Name
    }
}

$rows = New-Object System.Collections.Generic.List[object]
foreach ($process in $xml.SelectNodes('//Category-Detail//Process')) {
    $description = [string]$process.Description
    if ($description -notmatch '\((\d+)\)$') { continue }
    $processId = [int]$Matches[1]
    if (-not $manifestByPid.ContainsKey($processId)) { continue }
    $category = [string]$process.ParentNode.Name
    $pages = [int64]$process.Pages
    $rows.Add([pscustomobject]@{
        pid = $processId
        category = $category
        pages = $pages
    })
}

$byProcess = foreach ($group in ($rows | Group-Object pid)) {
    $manifestEntry = $manifestByPid[[int]$group.Name]
    $categoryRows = foreach ($categoryGroup in ($group.Group | Group-Object category)) {
        $pages = [int64](($categoryGroup.Group | Measure-Object pages -Sum).Sum)
        [pscustomobject]@{
            category = $categoryGroup.Name
            pages = $pages
            residentMiB = [math]::Round(($pages * $pageSize / 1MB), 3)
        }
    }
    $totalPages = [int64](($group.Group | Measure-Object pages -Sum).Sum)
    [pscustomobject]@{
        pid = $manifestEntry.pid
        parentPid = $manifestEntry.parentPid
        name = $manifestEntry.name
        pages = $totalPages
        residentMiB = [math]::Round(($totalPages * $pageSize / 1MB), 3)
        categories = @($categoryRows | Sort-Object residentMiB -Descending)
    }
}

$treePages = [int64](($rows | Measure-Object pages -Sum).Sum)
$result = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    source = (Resolve-Path -LiteralPath $ResidentSetXmlPath).Path
    processTreeManifest = (Resolve-Path -LiteralPath $ProcessTreeManifestPath).Path
    rawTraceRetainedPrivate = $true
    pageSizeBytes = $pageSize
    matchedProcessCount = @($byProcess).Count
    manifestProcessCount = $manifestByPid.Count
    filteredTreePages = $treePages
    filteredTreeResidentMiB = [math]::Round(($treePages * $pageSize / 1MB), 3)
    processes = @($byProcess | Sort-Object residentMiB -Descending)
    limitation = 'WPR resident-set categories are ETW system resident-set evidence. They include categories such as page tables and kernel stacks and are not a substitute for per-process private working-set or unique physical-page accounting.'
}

$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding utf8
[pscustomobject]@{
    matchedProcessCount = $result.matchedProcessCount
    filteredTreeResidentMiB = $result.filteredTreeResidentMiB
    outputPath = (Resolve-Path -LiteralPath $OutputPath).Path
}
