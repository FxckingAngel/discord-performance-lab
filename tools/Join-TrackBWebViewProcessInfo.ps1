[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ProcessTreePath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $WebViewProcessInfoPath,

    [string] $OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$tree = Get-Content -LiteralPath $ProcessTreePath -Raw | ConvertFrom-Json
$inventory = Get-Content -LiteralPath $WebViewProcessInfoPath -Raw | ConvertFrom-Json
$latest = @($tree.samples[-1].processes | Where-Object { $null -ne $_.pid })
$inventoryByPid = @{}
foreach ($process in @($inventory.processes)) {
    if ($null -ne $process.processId) {
        $inventoryByPid[[int]$process.processId] = $process
    }
}

$joined = foreach ($process in $latest) {
    $inventoryProcess = $inventoryByPid[[int]$process.pid]
    [pscustomobject]@{
        pid = [int]$process.pid
        windowsRole = [string]$process.role
        webViewKind = if ($inventoryProcess) { [string]$inventoryProcess.kind } else { $null }
        activeFrameCount = if ($inventoryProcess) { [int]$inventoryProcess.activeFrameCount } else { $null }
        privateWorkingSetMiB = [math]::Round([double]$process.privateWorkingSetMiB, 3)
        privateBytesMiB = [math]::Round([double]$process.privateMemoryMiB, 3)
        matched = ($null -ne $inventoryProcess)
    }
}

$rendererRows = @($joined | Where-Object windowsRole -eq 'renderer')
$inventoryRendererRows = @($inventory.processes | Where-Object kind -eq 'Renderer')
$rendererMatch = $rendererRows.Count -eq 1 -and $inventoryRendererRows.Count -eq 1 -and $rendererRows[0].pid -eq [int]$inventoryRendererRows[0].processId
$result = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    policy = 'Local aggregate join. No command lines, page content, URLs, cookies, tokens, or heap objects are copied.'
    processTreeSource = (Resolve-Path -LiteralPath $ProcessTreePath).Path
    webViewProcessInfoSource = (Resolve-Path -LiteralPath $WebViewProcessInfoPath).Path
    webViewInventoryCapturedAt = $inventory.capturedAt
    windowsProcessCount = $latest.Count
    webViewProcessCount = @($inventory.processes).Count
    webViewExcludesCrashpad = @($inventory.processes | Where-Object kind -eq 'Crashpad').Count -eq 0
    processCountDelta = $latest.Count - @($inventory.processes).Count
    matchedCount = @($joined | Where-Object matched).Count
    rendererPidMatch = $rendererMatch
    joinedProcesses = @($joined)
}

if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding utf8
}

$result | ConvertTo-Json -Depth 6
