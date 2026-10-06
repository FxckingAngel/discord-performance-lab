[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ProcessTreePath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $CdpProcessInfoPath,

    [string] $OutputPath
)

$tree = Get-Content -LiteralPath $ProcessTreePath -Raw | ConvertFrom-Json
$cdp = Get-Content -LiteralPath $CdpProcessInfoPath -Raw | ConvertFrom-Json
$latest = @($tree.samples[-1].processes)
$cdpByPid = @{}
foreach ($process in @($cdp.processes)) {
    if ($null -ne $process.id) {
        $cdpByPid[[int] $process.id] = $process
    }
}

$joined = foreach ($process in $latest) {
    $cdpProcess = $cdpByPid[[int] $process.pid]
    [pscustomobject]@{
        pid = [int] $process.pid
        windowsRole = [string] $process.role
        cdpType = if ($cdpProcess) { [string] $cdpProcess.type } else { $null }
        cdpCpuSeconds = if ($cdpProcess) { [double] $cdpProcess.cpuTime } else { $null }
        privateWorkingSetMiB = [math]::Round(([double] $process.workingSetPrivateBytes / 1MB), 3)
        privateBytesMiB = [math]::Round(([double] $process.privateBytes / 1MB), 3)
        handles = [int] $process.handles
        threads = [int] $process.threads
        cdpMatched = ($null -ne $cdpProcess)
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    policy = 'Local aggregate join. No command lines, page content, URLs, cookies, tokens, or heap objects are copied.'
    processTreeSource = (Resolve-Path -LiteralPath $ProcessTreePath).Path
    cdpProcessInfoSource = (Resolve-Path -LiteralPath $CdpProcessInfoPath).Path
    windowsProcessCount = $latest.Count
    cdpProcessCount = @($cdp.processes).Count
    matchedCount = @($joined | Where-Object cdpMatched).Count
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
