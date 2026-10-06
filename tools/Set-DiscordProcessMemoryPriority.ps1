[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [ValidateSet('normal', 'below-normal', 'low', 'very-low')]
    [string] $Priority = 'normal',

    [string[]] $ExcludeRole = @(),

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB'
)

Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class DiscordProcessMemoryNative
{
    private const uint ProcessSetInformation = 0x0200;
    private const uint ProcessQueryInformation = 0x0400;
    private const int ProcessMemoryPriority = 0;

    [StructLayout(LayoutKind.Sequential)]
    private struct MemoryPriorityInformation
    {
        public uint MemoryPriority;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(uint access, bool inheritHandle, uint processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetProcessInformation(
        IntPtr processHandle,
        int processInformationClass,
        ref MemoryPriorityInformation processInformation,
        uint processInformationSize);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);

    public static void Set(uint processId, uint priority)
    {
        IntPtr handle = OpenProcess(ProcessSetInformation | ProcessQueryInformation, false, processId);
        if (handle == IntPtr.Zero)
        {
            throw new Win32Exception(Marshal.GetLastWin32Error());
        }

        try
        {
            MemoryPriorityInformation information = new MemoryPriorityInformation
            {
                MemoryPriority = priority
            };
            if (!SetProcessInformation(
                handle,
                ProcessMemoryPriority,
                ref information,
                (uint)Marshal.SizeOf(typeof(MemoryPriorityInformation))))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
        }
        finally
        {
            CloseHandle(handle);
        }
    }
}
'@

$priorityValues = @{
    'very-low' = 1
    'low' = 2
    'below-normal' = 4
    'normal' = 5
}
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

$results = foreach ($process in @($processes | Where-Object { $treePids.Contains([int] $_.ProcessId) })) {
    $role = 'browser'
    if ($process.CommandLine -match '--type=([^\s]+)') {
        $role = $Matches[1]
    }
    if ($process.CommandLine -match '--utility-sub-type=([^\s]+)') {
        $role = "$role/$($Matches[1])"
    }
    $excluded = $ExcludeRole -contains $role
    $targetPriority = if ($excluded) { [uint32] 5 } else { [uint32] $priorityValues[$Priority] }
    try {
        [DiscordProcessMemoryNative]::Set([uint32] $process.ProcessId, $targetPriority)
        [pscustomobject]@{
            pid = [int] $process.ProcessId
            parentPid = [int] $process.ParentProcessId
            role = $role
            priority = if ($excluded) { 'normal' } else { $Priority }
            status = if ($excluded) { 'preserved' } else { 'applied' }
        }
    }
    catch {
        [pscustomobject]@{
            pid = [int] $process.ProcessId
            parentPid = [int] $process.ParentProcessId
            role = $role
            priority = $Priority
            status = 'failed'
            error = $_.Exception.Message
        }
    }
}

$results | ConvertTo-Json -Depth 4
if (@($results | Where-Object status -eq 'failed').Count -gt 0) {
    exit 1
}
