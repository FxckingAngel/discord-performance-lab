[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [ValidateSet('ecoqos', 'system-managed')]
    [string] $Mode = 'system-managed',

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB'
)

Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class DiscordProcessQoSNative
{
    private const uint ProcessSetInformation = 0x0200;
    private const uint ProcessQueryInformation = 0x0400;
    private const int ProcessPowerThrottling = 4;
    private const uint CurrentVersion = 1;
    private const uint ExecutionSpeed = 1;

    [StructLayout(LayoutKind.Sequential)]
    private struct ProcessPowerThrottlingState
    {
        public uint Version;
        public uint ControlMask;
        public uint StateMask;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(uint access, bool inheritHandle, uint processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetProcessInformation(
        IntPtr processHandle,
        int processInformationClass,
        ref ProcessPowerThrottlingState processInformation,
        uint processInformationSize);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);

    public static void Set(uint processId, bool ecoQoS)
    {
        IntPtr handle = OpenProcess(ProcessSetInformation | ProcessQueryInformation, false, processId);
        if (handle == IntPtr.Zero)
        {
            throw new Win32Exception(Marshal.GetLastWin32Error());
        }

        try
        {
            ProcessPowerThrottlingState state = new ProcessPowerThrottlingState
            {
                Version = CurrentVersion,
                ControlMask = ecoQoS ? ExecutionSpeed : 0,
                StateMask = ecoQoS ? ExecutionSpeed : 0
            };
            if (!SetProcessInformation(
                handle,
                ProcessPowerThrottling,
                ref state,
                (uint)Marshal.SizeOf(typeof(ProcessPowerThrottlingState))))
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

$ecoQoS = $Mode -eq 'ecoqos'
$results = foreach ($process in @($processes | Where-Object { $treePids.Contains([int] $_.ProcessId) })) {
    try {
        [DiscordProcessQoSNative]::Set([uint32] $process.ProcessId, $ecoQoS)
        [pscustomobject]@{
            pid = [int] $process.ProcessId
            parentPid = [int] $process.ParentProcessId
            mode = $Mode
            status = 'applied'
        }
    }
    catch {
        [pscustomobject]@{
            pid = [int] $process.ProcessId
            parentPid = [int] $process.ParentProcessId
            mode = $Mode
            status = 'failed'
            error = $_.Exception.Message
        }
    }
}

$results | ConvertTo-Json -Depth 4
if (@($results | Where-Object status -eq 'failed').Count -gt 0) {
    exit 1
}
