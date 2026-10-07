[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB'
)

Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class DiscordProcessMemoryQueryNative
{
    private const uint ProcessQueryLimitedInformation = 0x1000;
    private const int ProcessMemoryPriority = 0;

    [StructLayout(LayoutKind.Sequential)]
    private struct MemoryPriorityInformation
    {
        public uint MemoryPriority;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(uint access, bool inheritHandle, uint processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetProcessInformation(
        IntPtr processHandle,
        int processInformationClass,
        out MemoryPriorityInformation processInformation,
        uint processInformationSize);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);

    public static uint Get(uint processId)
    {
        IntPtr handle = OpenProcess(ProcessQueryLimitedInformation, false, processId);
        if (handle == IntPtr.Zero)
        {
            throw new Win32Exception(Marshal.GetLastWin32Error());
        }

        try
        {
            MemoryPriorityInformation information;
            if (!GetProcessInformation(
                handle,
                ProcessMemoryPriority,
                out information,
                (uint)Marshal.SizeOf(typeof(MemoryPriorityInformation))))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
            return information.MemoryPriority;
        }
        finally
        {
            CloseHandle(handle);
        }
    }
}
'@

$processes = @(Get-CimInstance Win32_Process -Filter "Name='$ProcessName.exe'")
if (-not @($processes | Where-Object { [int] $_.ProcessId -eq $RootPid })) {
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

$priorityNames = @{
    1 = 'very-low'
    2 = 'low'
    3 = 'below-normal'
    4 = 'below-normal'
    5 = 'normal'
}
$results = foreach ($process in @($processes | Where-Object { $treePids.Contains([int] $_.ProcessId) })) {
    $role = 'browser'
    if ($process.CommandLine -match '--type=([^\s]+)') {
        $role = $Matches[1]
    }
    if ($process.CommandLine -match '--utility-sub-type=([^\s]+)') {
        $role = "$role/$($Matches[1])"
    }
    try {
        $priority = [DiscordProcessMemoryQueryNative]::Get([uint32] $process.ProcessId)
        [pscustomobject]@{
            pid = [int] $process.ProcessId
            parentPid = [int] $process.ParentProcessId
            role = $role
            priorityValue = $priority
            priority = if ($priorityNames.ContainsKey([int] $priority)) { $priorityNames[[int] $priority] } else { 'unknown' }
            status = 'read'
        }
    }
    catch {
        [pscustomobject]@{
            pid = [int] $process.ProcessId
            parentPid = [int] $process.ParentProcessId
            role = $role
            status = 'failed'
            error = $_.Exception.Message
        }
    }
}

$results | ConvertTo-Json -Depth 4
if (@($results | Where-Object status -eq 'failed').Count -gt 0) {
    exit 1
}
