[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) 'working-set-pages.json')
)

Add-Type @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public sealed class WorkingSetPageStats
{
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(uint access, bool inheritHandle, int processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);

    [DllImport("psapi.dll", SetLastError = true)]
    private static extern bool QueryWorkingSet(IntPtr process, IntPtr buffer, int size);

    public static object Read(int processId)
    {
        const uint QueryInformation = 0x0400;
        var process = OpenProcess(QueryInformation, false, processId);
        if (process == IntPtr.Zero)
        {
            return new { processId, available = false, error = new Win32Exception(Marshal.GetLastWin32Error()).Message };
        }

        try
        {
            var size = 1024 * 1024;
            for (var attempt = 0; attempt < 4; attempt++)
            {
                var buffer = Marshal.AllocHGlobal(size);
                try
                {
                    if (!QueryWorkingSet(process, buffer, size))
                    {
                        var error = Marshal.GetLastWin32Error();
                        if (error == 24 || error == 122)
                        {
                            size *= 2;
                            continue;
                        }
                        return new { processId, available = false, error = new Win32Exception(error).Message };
                    }

                    var count = Marshal.ReadIntPtr(buffer).ToInt64();
                    long sharedFlagPages = 0;
                    long nonSharedFlagPages = 0;
                    long sharedByCountPages = 0;
                    long singleOwnerPages = 0;
                    var entrySize = IntPtr.Size;
                    for (long index = 0; index < count; index++)
                    {
                        var offset = checked((int)(IntPtr.Size + index * entrySize));
                        var flags = unchecked((ulong)Marshal.ReadIntPtr(IntPtr.Add(buffer, offset)).ToInt64());
                        if ((flags & 1UL) == 0) continue;
                        var isShared = ((flags >> 15) & 1UL) != 0;
                        var shareCount = (flags >> 1) & 7UL;
                        if (isShared) sharedFlagPages++; else nonSharedFlagPages++;
                        if (shareCount > 1) sharedByCountPages++; else singleOwnerPages++;
                    }

                    var pageSize = Environment.SystemPageSize;
                    return new
                    {
                        processId,
                        available = true,
                        pageSize,
                        residentPages = count,
                        residentBytes = checked(count * pageSize),
                        sharedFlagPages,
                        sharedFlagResidentBytes = checked(sharedFlagPages * pageSize),
                        nonSharedFlagPages,
                        nonSharedFlagResidentBytes = checked(nonSharedFlagPages * pageSize),
                        sharedByCountPages,
                        sharedByCountResidentBytes = checked(sharedByCountPages * pageSize),
                        singleOwnerPages,
                        singleOwnerResidentBytes = checked(singleOwnerPages * pageSize)
                    };
                }
                finally
                {
                    Marshal.FreeHGlobal(buffer);
                }
            }
            return new { processId, available = false, error = "Working-set buffer did not fit after four attempts." };
        }
        finally
        {
            CloseHandle(process);
        }
    }
}
'@

function Get-RootedProcesses {
    $all = @(Get-CimInstance Win32_Process)
    $byPid = @{}
    foreach ($row in $all) { $byPid[[int] $row.ProcessId] = $row }
    if (-not $byPid.ContainsKey($RootPid)) { throw "Root PID $RootPid was not found." }
    $pids = [System.Collections.Generic.HashSet[int]]::new()
    $queue = [System.Collections.Generic.Queue[int]]::new()
    [void] $pids.Add($RootPid)
    $queue.Enqueue($RootPid)
    while ($queue.Count -gt 0) {
        $parent = $queue.Dequeue()
        foreach ($row in $all | Where-Object { [int] $_.ParentProcessId -eq $parent }) {
            $child = [int] $row.ProcessId
            if ($pids.Add($child)) { $queue.Enqueue($child) }
        }
    }
    return @($all | Where-Object { $pids.Contains([int] $_.ProcessId) })
}

$rows = foreach ($process in Get-RootedProcesses) {
    $stats = [WorkingSetPageStats]::Read([int] $process.ProcessId)
    $role = if ([int] $process.ProcessId -eq $RootPid) { 'native-shell' } elseif ($process.CommandLine -match '--type=([^\s]+)') { $Matches[1] } else { 'browser' }
    if ($role -eq 'utility' -and $process.CommandLine -match '--utility-sub-type=([^\s]+)') { $role = "utility/$($Matches[1])" }
    [pscustomobject]@{
        pid = [int] $process.ProcessId
        parentPid = [int] $process.ParentProcessId
        name = $process.Name
        role = $role
        stats = $stats
    }
}

$available = @($rows | Where-Object { $_.stats.available })
$summary = [pscustomobject]@{
    schemaVersion = 1
    rootPid = $RootPid
    capturedAt = [DateTime]::UtcNow.ToString('o')
    processCount = $rows.Count
    availableProcessCount = $available.Count
    pageSource = 'QueryWorkingSet; per-process resident-page flags'
    sharedDefinition = 'PSAPI Shared flag and ShareCount classifications; neither is cross-process physical-page deduplication'
    processes = @($rows)
    totals = [pscustomobject]@{
        residentBytes = [long](($available | ForEach-Object { $_.stats.residentBytes } | Measure-Object -Sum).Sum)
        sharedFlagResidentBytes = [long](($available | ForEach-Object { $_.stats.sharedFlagResidentBytes } | Measure-Object -Sum).Sum)
        nonSharedFlagResidentBytes = [long](($available | ForEach-Object { $_.stats.nonSharedFlagResidentBytes } | Measure-Object -Sum).Sum)
        sharedByCountResidentBytes = [long](($available | ForEach-Object { $_.stats.sharedByCountResidentBytes } | Measure-Object -Sum).Sum)
        singleOwnerResidentBytes = [long](($available | ForEach-Object { $_.stats.singleOwnerResidentBytes } | Measure-Object -Sum).Sum)
    }
}

$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$summary | Select-Object rootPid, processCount, availableProcessCount, @{Name='residentMiB';Expression={[math]::Round($_.totals.residentBytes / 1MB, 3)}}, @{Name='sharedFlagMiB';Expression={[math]::Round($_.totals.sharedFlagResidentBytes / 1MB, 3)}}, @{Name='nonSharedFlagMiB';Expression={[math]::Round($_.totals.nonSharedFlagResidentBytes / 1MB, 3)}}, @{Name='sharedByCountMiB';Expression={[math]::Round($_.totals.sharedByCountResidentBytes / 1MB, 3)}}, @{Name='singleOwnerMiB';Expression={[math]::Round($_.totals.singleOwnerResidentBytes / 1MB, 3)}} | Format-List
Write-Output "raw=$OutputPath"
