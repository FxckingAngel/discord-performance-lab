[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB',

    [int[]] $Ports = @(9222, 9229, 8315)
)

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path (Split-Path -Parent $PSScriptRoot) ('artifacts/phase2-cdp-test-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json')
}

$processes = @(Get-CimInstance Win32_Process -Filter "Name='$ProcessName.exe'")
$commandLines = @($processes | Select-Object -ExpandProperty CommandLine)
$portResults = foreach ($port in $Ports) {
    $versionUri = "http://127.0.0.1:$port/json/version"
    $listUri = "http://127.0.0.1:$port/json/list"
    $versionAvailable = $false
    $targetCount = $null
    try {
        $version = Invoke-RestMethod -Uri $versionUri -Method Get -TimeoutSec 2 -ErrorAction Stop
        $versionAvailable = $true
        try {
            $targets = @(Invoke-RestMethod -Uri $listUri -Method Get -TimeoutSec 2 -ErrorAction Stop)
            $targetCount = $targets.Count
        }
        catch {
            $targetCount = $null
        }
    }
    catch {
        # A closed localhost endpoint is the expected result for a stock launch.
    }
    [pscustomobject]@{
        port = $port
        versionEndpointAvailable = $versionAvailable
        targetCount = $targetCount
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = [DateTime]::UtcNow
    processName = $ProcessName
    processCount = $processes.Count
    remoteDebuggingPortFlagPresent = [bool](@($commandLines | Where-Object { $_ -match '--remote-debugging-port(?:=|\s)' }))
    inspectorFlagPresent = [bool](@($commandLines | Where-Object { $_ -match '--inspect(?:=|\s|$)' }))
    localhostEndpoints = @($portResults)
    policy = 'Probe is localhost-only and records endpoint availability, not page contents, titles, URLs, heap data, or credentials.'
}
$parent = Split-Path -Parent $OutputPath
if ($parent) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
