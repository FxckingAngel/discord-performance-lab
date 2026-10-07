[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$EtlPath,

    [Parameter(Mandatory = $true)]
    [int]$ProcessId,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [string]$XperfPath = 'C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\xperf.exe',

    [switch]$EnableSymbols
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $EtlPath -PathType Leaf)) {
    throw "ETL not found: $EtlPath"
}
if (-not (Test-Path -LiteralPath $XperfPath -PathType Leaf)) {
    throw "xperf not found: $XperfPath"
}

$process = Get-Process -Id $ProcessId -ErrorAction Stop
$modules = @($process.Modules | ForEach-Object {
    [pscustomobject]@{
        name = $_.ModuleName
        path = $_.FileName
        base = $_.BaseAddress.ToInt64()
        size = $_.ModuleMemorySize
    }
})

$temp = Join-Path ([IO.Path]::GetTempPath()) ("track-b-heapsnapshot-" + [guid]::NewGuid().ToString('N') + '.txt')
try {
    $symbolCache = Join-Path ([IO.Path]::GetTempPath()) 'track-b-symbol-cache'
    if ($EnableSymbols) {
        New-Item -ItemType Directory -Force -Path $symbolCache | Out-Null
        $env:_NT_SYMBOL_PATH = "srv*$symbolCache*https://msdl.microsoft.com/download/symbols"
        $env:_NT_SYMCACHE_PATH = $symbolCache
        & $XperfPath -i $EtlPath -o $temp -symbols -a heapsnapshot -data 2>&1 | Out-Null
    }
    else {
        & $XperfPath -i $EtlPath -o $temp -a heapsnapshot -data 2>&1 | Out-Null
    }
    if ($LASTEXITCODE -ne 0) {
        throw "xperf heapsnapshot decoder failed with exit code $LASTEXITCODE"
    }

    $lines = @(Get-Content -LiteralPath $temp)
    $snapshotInstances = 0
    $allocationCount = 0
    $stackRows = New-Object System.Collections.Generic.List[object]
    $currentStackId = $null
    $currentIdenticalReferences = 0
    $currentFrames = New-Object System.Collections.Generic.List[string]

    function Resolve-Module([string]$frame) {
        if ($frame -match '^([^\s]+\.dll)\s+') {
            return $Matches[1]
        }
        $address = [Convert]::ToInt64($frame.Substring(2), 16)
        $match = $modules | Where-Object { $address -ge $_.base -and $address -lt ($_.base + $_.size) } | Select-Object -First 1
        if ($match) { return $match.name }
        return 'unresolved'
    }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match 'Total allocation count \(all instances\) = (\d+)') {
            $allocationCount = [int]$Matches[1]
        }
        elseif ($line -match 'Total heap snapshot instances : (\d+)') {
            $snapshotInstances = [int]$Matches[1]
        }
        elseif ($line -match 'StackID : (\d+), Identical stack\(ID\) so far (\d+), stack depth=(\d+)') {
            $currentStackId = [int]$Matches[1]
            $currentIdenticalReferences = [int]$Matches[2]
            $currentFrames = New-Object System.Collections.Generic.List[string]
        }
        elseif ($null -ne $currentStackId -and $line -match '^\s+(0x[0-9a-fA-F]+)\s*$') {
            $currentFrames.Add($Matches[1])
        }
        elseif ($null -ne $currentStackId -and $EnableSymbols -and $line -match '^\s+([^\s]+\.dll)\s+(.+)$') {
            $currentFrames.Add($Matches[1] + ' ' + $Matches[2])
        }
        elseif ($null -ne $currentStackId -and $line -match 'Allocation size\(s\) :\s*(.*)$') {
            $sizes = @($Matches[1] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int64]$_ })
            $resolvedModules = @($currentFrames | ForEach-Object { Resolve-Module $_ } | Sort-Object -Unique)
            $stackRows.Add([pscustomobject]@{
                stackId = $currentStackId
                identicalReferences = $currentIdenticalReferences
                allocationCount = $sizes.Count
                outstandingBytes = [int64](($sizes | Measure-Object -Sum).Sum)
                averageAllocationBytes = if ($sizes.Count) { [math]::Round((($sizes | Measure-Object -Average).Average), 2) } else { 0 }
                modules = $resolvedModules
                topModule = if ($resolvedModules.Count) { $resolvedModules[0] } else { 'unresolved' }
                symbolized = [bool]$EnableSymbols
            })
            $currentStackId = $null
        }
    }

    $totalBytes = [int64](($stackRows.outstandingBytes | Measure-Object -Sum).Sum)
    $totalAllocations = [int64](($stackRows.allocationCount | Measure-Object -Sum).Sum)
    $families = @($stackRows | Group-Object topModule | ForEach-Object {
        $bytes = [int64](($_.Group.outstandingBytes | Measure-Object -Sum).Sum)
        $count = [int64](($_.Group.allocationCount | Measure-Object -Sum).Sum)
        [pscustomobject]@{
            family = $_.Name
            outstandingBytes = $bytes
            outstandingMiB = [math]::Round($bytes / 1MB, 6)
            allocationCount = $count
            averageAllocationBytes = if ($count) { [math]::Round($bytes / $count, 2) } else { 0 }
            percentOfDecodedHeap = if ($totalBytes) { [math]::Round(100 * $bytes / $totalBytes, 2) } else { 0 }
            confidence = if ($EnableSymbols) { 'medium; public symbols, no private Chromium symbols' } else { 'low; module-only mapping, no symbols' }
        }
    } | Sort-Object outstandingBytes -Descending)

    $result = [ordered]@{
        schemaVersion = 1
        generatedAt = (Get-Date).ToUniversalTime().ToString('o')
        processId = $ProcessId
        source = [IO.Path]::GetFullPath($EtlPath)
        rawTraceRetainedPrivate = $true
        snapshotInstances = if ($snapshotInstances -gt 0) { $snapshotInstances } else { $null }
        decodedAllocationCount = $totalAllocations
        decodedOutstandingBytes = $totalBytes
        decodedOutstandingMiB = [math]::Round($totalBytes / 1MB, 6)
        symbolized = [bool]$EnableSymbols
        limitation = 'HeapSnapshot output contains the outstanding allocations represented in the captured snapshot instance; it is not a complete private working-set ledger.'
        families = @($families)
        stacks = @($stackRows | Sort-Object outstandingBytes -Descending)
    }
    $parent = Split-Path -Parent $OutputPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
}
finally {
    Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
}
