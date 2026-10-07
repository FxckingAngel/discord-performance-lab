[CmdletBinding()]
param(
    [string] $ExecutablePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'),
    [ValidateNotNullOrEmpty()] [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-blank-boundary-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$residentScript = Join-Path $PSScriptRoot 'Measure-TrackBResidentMemoryTypes.ps1'
if (-not (Test-Path -LiteralPath $residentScript -PathType Leaf)) { throw "Resident classifier was not found: $residentScript" }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$diagnostic = $null
try {
    $diagnostic = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-blank' -PassThru
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    do { Start-Sleep -Milliseconds 250; $diagnostic.Refresh() } while ((!$diagnostic.Responding -or $diagnostic.MainWindowHandle -eq 0) -and [DateTime]::UtcNow -lt $deadline)
    if (-not $diagnostic.Responding) { throw 'Blank diagnostic did not become responsive.' }
    Start-Sleep -Seconds 10
    $all = @(Get-CimInstance Win32_Process)
    $seen = [System.Collections.Generic.HashSet[int]]::new()
    $pending = [System.Collections.Generic.Queue[int]]::new()
    $pending.Enqueue([int]$diagnostic.Id)
    while ($pending.Count -gt 0) {
        $parentPid = $pending.Dequeue()
        foreach ($candidate in @($all | Where-Object { [int]$_.ParentProcessId -eq $parentPid })) {
            if ($seen.Add([int]$candidate.ProcessId)) { $pending.Enqueue([int]$candidate.ProcessId) }
        }
    }
    $renderer = @($all | Where-Object { $seen.Contains([int]$_.ProcessId) -and $_.CommandLine -match '--type=renderer(?:\s|$)' } | Select-Object -First 1)[0]
    if (-not $renderer) { throw 'Blank renderer was not found.' }
    $residentPath = Join-Path $OutputDirectory 'renderer-resident-types.json'
    $resident = Start-Process -FilePath (Get-Command powershell.exe).Source -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile','-File',$residentScript,'-ProcessId',"$([int]$renderer.ProcessId)",'-Role','renderer','-OutputPath',$residentPath)
    if ($resident.ExitCode -ne 0) { throw "Blank resident classification failed with exit code $($resident.ExitCode)." }
    [pscustomobject]@{ result = 'CAPTURED'; rootPid = [int]$diagnostic.Id; rendererPid = [int]$renderer.ProcessId; outputPath = (Resolve-Path -LiteralPath $residentPath).Path; policy = 'Blank runtime-floor resident classification. Raw process metadata remains local.' } | ConvertTo-Json -Depth 4
}
finally {
    if ($diagnostic) {
        $current = Get-Process -Id $diagnostic.Id -ErrorAction SilentlyContinue
        if ($current) { [void]$current.CloseMainWindow(); if (-not $current.WaitForExit(8000)) { throw "Blank diagnostic $($diagnostic.Id) did not close normally." } }
    }
}
