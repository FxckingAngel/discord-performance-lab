[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB'
)

$processes = @(Get-CimInstance Win32_Process -Filter "Name='$ProcessName.exe'")
$root = @($processes | Where-Object { [int] $_.ProcessId -eq $RootPid })
if ($root.Count -eq 0) {
    throw "Root PID $RootPid was not found among $ProcessName processes."
}

$treePids = [System.Collections.Generic.HashSet[int]]::new()
$pending = [System.Collections.Generic.Queue[int]]::new()
[void] $treePids.Add($RootPid)
$pending.Enqueue($RootPid)
while ($pending.Count -gt 0) {
    $parentPid = $pending.Dequeue()
    foreach ($child in @($processes | Where-Object { [int] $_.ParentProcessId -eq $parentPid })) {
        $childPid = [int] $child.ProcessId
        if ($treePids.Add($childPid)) {
            $pending.Enqueue($childPid)
        }
    }
}

function Get-Role {
    param([object] $Process)
    $role = 'browser'
    if ($Process.CommandLine -match '--type=([^\s]+)') {
        $role = $Matches[1]
    }
    if ($Process.CommandLine -match '--utility-sub-type=([^\s]+)') {
        $role = "$role/$($Matches[1])"
    }
    return $role
}

$map = foreach ($process in @($processes | Where-Object { $treePids.Contains([int] $_.ProcessId) })) {
    [pscustomobject]@{
        pid = [int] $process.ProcessId
        parentPid = [int] $process.ParentProcessId
        role = Get-Role -Process $process
        commandLine = $process.CommandLine
    }
}
$result = [pscustomobject]@{
    schemaVersion = 1
    processName = $ProcessName
    rootPid = $RootPid
    capturedAt = [DateTime]::UtcNow
    warning = 'Local-only diagnostic artifact. Command lines may contain user-data paths or other sensitive launch metadata. Do not publish.'
    processes = @($map)
}
$parent = Split-Path -Parent $OutputPath
if ($parent) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
[pscustomobject]@{
    rootPid = $RootPid
    processCount = @($map).Count
    outputPath = $OutputPath
}
