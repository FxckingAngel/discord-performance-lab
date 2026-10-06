[CmdletBinding()]
param(
    [string] $ExecutablePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'),

    [ValidateRange(1, 65535)]
    [int] $Port = 9228,

    [ValidateRange(1, 60)]
    [int] $DurationSeconds = 10,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) ('benchmarks/raw/track-b-cdp-trace-checkpoint-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$node = Get-Command node.exe -ErrorAction Stop
$traceScript = Join-Path $PSScriptRoot 'Capture-TrackBCdpTrace.mjs'
if (-not (Test-Path -LiteralPath $traceScript -PathType Leaf)) { throw "Trace script was not found: $traceScript" }

$existing = @(Get-Process -Name 'KoroneDiscordShell' -ErrorAction SilentlyContinue)
if ($existing.Count -gt 0) {
    throw "A Track B shell is already running (PID $($existing.Id -join ', ')). Close it before starting a diagnostic checkpoint."
}

$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

$process = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-authenticated' -PassThru
$traceCompleted = $false
try {
    $ready = $false
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 1)
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) {
                $ready = $true
                break
            }
        }
        catch {
            # The diagnostic endpoint may take a few seconds to open.
        }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    if (-not $ready) { throw "Track B diagnostic CDP endpoint did not become ready on port $Port." }

    Write-Host 'Complete these steps manually:'
    Write-Host '1. Log into Discord normally if needed.'
    Write-Host '2. Navigate to the requested test channel or DM.'
    Write-Host '3. Leave the intended route, window size, and workload visible.'
    $confirmation = Read-Host 'Type READY to begin the aggregate trace'
    if ($confirmation -cne 'READY') { throw 'Manual checkpoint was not confirmed. No trace was started.' }

    & $node.Source $traceScript $Port $DurationSeconds $OutputPath
    if ($LASTEXITCODE -ne 0) { throw "CDP trace failed with exit code $LASTEXITCODE." }
    $traceCompleted = $true
    [pscustomobject]@{
        result = 'PASS'
        checkpoint = 'READY'
        traceCompleted = $traceCompleted
        durationSeconds = $DurationSeconds
        outputPath = (Resolve-Path -LiteralPath $OutputPath).Path
    }
}
finally {
    $current = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
    if ($current) {
        [void] $current.CloseMainWindow()
        $current.WaitForExit(8000)
    }
    if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
        throw "Diagnostic checkpoint process $($process.Id) did not exit through its normal close action."
    }
    Start-Sleep -Seconds 2
    Start-Process -FilePath $resolvedExecutable | Out-Null
}
