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
$rootPid = [int] $launched.Id
$firstProcessAt = $null
$firstWindowAt = $null
$windowTitle = ''
$windowResponding = $false
$stableCount = 0
$lastCount = -1
$observed = @()

function Select-RootedProcessTree {
    param(
        [Parameter(Mandatory = $true)] [object[]] $Processes,
        [Parameter(Mandatory = $true)] [int] $TreeRootPid
    )

    $treePids = [System.Collections.Generic.HashSet[int]]::new()
    $pending = [System.Collections.Generic.Queue[int]]::new()
    [void] $treePids.Add($TreeRootPid)
    $pending.Enqueue($TreeRootPid)
    while ($pending.Count -gt 0) {
        $parentPid = $pending.Dequeue()
        foreach ($child in @($Processes | Where-Object { [int] $_.ParentProcessId -eq $parentPid })) {
            $childPid = [int] $child.ProcessId
            if ($treePids.Add($childPid)) {
                $pending.Enqueue($childPid)
            }
        }
    }
    @($Processes | Where-Object { $treePids.Contains([int] $_.ProcessId) })
}

while ($stableCount -lt $StableSamples) {
    Start-Sleep -Seconds $PollIntervalSeconds
    $current = @(Get-CimInstance Win32_Process)
    $current = @(Select-RootedProcessTree -Processes $current -TreeRootPid $rootPid)
    if ($current.Count -gt 0 -and -not $firstProcessAt) {
        $firstProcessAt = $watch.Elapsed.TotalSeconds
    }
    foreach ($item in $current) {
        try {
            $process = Get-Process -Id $item.ProcessId -ErrorAction Stop
            if ($process.MainWindowHandle -ne 0) {
                if (-not $firstWindowAt) { $firstWindowAt = $watch.Elapsed.TotalSeconds }
                $windowTitle = $process.MainWindowTitle
                $windowResponding = [bool] $process.Responding
                break
            }
        }
        catch [System.ArgumentException] {
            # A child can exit between the process query and the sample.
        }
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
        mainWindowPresent = ($null -ne $firstWindowAt)
        mainWindowTitle = $windowTitle
        mainWindowResponding = $windowResponding
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    executablePath = $resolvedExecutable
    processName = $ProcessName
    rootPid = $rootPid
    scenario = $Scenario
    processTreeFirstSeenSeconds = [math]::Round($firstProcessAt, 3)
    processTreeStableSeconds = [math]::Round($watch.Elapsed.TotalSeconds, 3)
    mainWindowFirstSeenSeconds = if ($null -ne $firstWindowAt) { [math]::Round($firstWindowAt, 3) } else { $null }
    mainWindowTitle = $windowTitle
    mainWindowResponding = $windowResponding
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
