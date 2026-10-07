[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ExecutablePath,

    [ValidateRange(1, 65535)]
    [int] $Port = 9224,

    [ValidateSet('--diagnostic-discord')]
    [string] $DiagnosticArgument = '--diagnostic-discord',

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-environment-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json') )
)

$ErrorActionPreference = 'Stop'
$fixedDiagnosticPort = 9224
if ($Port -ne $fixedDiagnosticPort) {
    throw "Diagnostic argument '$DiagnosticArgument' uses fixed CDP port $fixedDiagnosticPort; pass -Port $fixedDiagnosticPort."
}
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath).Path
$probe = Join-Path $PSScriptRoot 'Invoke-DiscordEnvironmentProbe.mjs'
if (-not (Test-Path -LiteralPath $probe -PathType Leaf)) { throw "Environment probe was not found: $probe" }
$node = (Get-Command node.exe -ErrorAction Stop).Source
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

$process = Start-Process -FilePath $resolvedExecutable -ArgumentList $DiagnosticArgument -PassThru
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
        catch { }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    if (-not $ready) { throw "Track B CDP endpoint did not become ready on port $Port." }

    & $node $probe $Port $OutputPath
    if ($LASTEXITCODE -ne 0) { throw "Sanitized environment probe failed with exit code $LASTEXITCODE." }
    [pscustomobject]@{
        result = 'CAPTURED'
        outputPath = (Resolve-Path -LiteralPath $OutputPath).Path
        diagnosticArgument = $DiagnosticArgument
        officialDiscordTouched = $false
    } | ConvertTo-Json -Depth 4
}
finally {
    $current = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
    if ($current) {
        [void]$current.CloseMainWindow()
        if (-not $current.WaitForExit(8000)) { throw "Track B diagnostic process $($process.Id) did not close normally." }
    }
}
