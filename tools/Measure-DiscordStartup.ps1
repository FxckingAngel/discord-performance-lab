[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ExecutablePath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ProcessName,

    [string[]] $ArgumentList = @(),

    [ValidateRange(1, 30)]
    [int] $PollIntervalSeconds = 1,

    [ValidateRange(2, 60)]
    [int] $StableSamples = 3,

    [ValidateNotNullOrEmpty()]
    [string] $Scenario = 'process-tree-startup',

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) 'startup.json')
)

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath).Path
$existing = @(Get-CimInstance Win32_Process -Filter "Name='$ProcessName.exe'" | Where-Object {
    $_.ExecutablePath -and ((Resolve-Path -LiteralPath $_.ExecutablePath -ErrorAction SilentlyContinue).Path -eq $resolvedExecutable)
})
if ($existing.Count -gt 0) {
    throw "An instance of $ProcessName is already running. Close it manually before measuring a new launch."
}

$watch = [System.Diagnostics.Stopwatch]::StartNew()
$launched = Start-Process -FilePath $resolvedExecutable -ArgumentList $ArgumentList -PassThru
$firstProcessAt = $null
$stableCount = 0
$lastCount = -1
$observed = @()

while ($stableCount -lt $StableSamples) {
    Start-Sleep -Seconds $PollIntervalSeconds
    $current = @(Get-CimInstance Win32_Process -Filter "Name='$ProcessName.exe'" | Where-Object {
        $_.ExecutablePath -and ((Resolve-Path -LiteralPath $_.ExecutablePath -ErrorAction SilentlyContinue).Path -eq $resolvedExecutable)
    })
    if ($current.Count -gt 0 -and -not $firstProcessAt) {
        $firstProcessAt = $watch.Elapsed.TotalSeconds
    }
    if ($current.Count -eq $lastCount -and $current.Count -gt 0) {
        $stableCount++
    }
    else {
        $stableCount = 0
    }
    $lastCount = $current.Count
    $observed += [pscustomobject]@{
        elapsedSeconds = [math]::Round($watch.Elapsed.TotalSeconds, 3)
        processCount = $current.Count
        pids = @($current | ForEach-Object ProcessId)
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    executablePath = $resolvedExecutable
    processName = $ProcessName
    scenario = $Scenario
    processTreeFirstSeenSeconds = [math]::Round($firstProcessAt, 3)
    processTreeStableSeconds = [math]::Round($watch.Elapsed.TotalSeconds, 3)
    stableSampleCount = $StableSamples
    observations = @($observed)
}

$parent = Split-Path -Parent $OutputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result | ConvertTo-Json -Depth 6
Write-Output "raw=$OutputPath"
