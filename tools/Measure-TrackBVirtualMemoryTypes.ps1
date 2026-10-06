[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int] $RootPid,

    [string] $ProcessName = 'KoroneDiscordShell',

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

if (-not $OutputPath) {
    $OutputPath = Join-Path (Get-Location) ('benchmarks/raw/track-b-virtual-memory-types-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json')
}

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class TrackBVirtualMemory {
    private const uint QueryInformation = 0x0400;
    private const uint MemCommit = 0x1000;
    private const uint MemPrivate = 0x20000;
    private const uint MemMapped = 0x40000;
    private const uint MemImage = 0x1000000;

    [StructLayout(LayoutKind.Sequential)]
    private struct MemoryBasicInformation {
        public IntPtr BaseAddress;
        public IntPtr AllocationBase;
        public uint AllocationProtect;
        public UIntPtr RegionSize;
        public uint State;
        public uint Protect;
        public uint Type;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(uint access, bool inheritHandle, int processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern UIntPtr VirtualQueryEx(IntPtr process, IntPtr address, out MemoryBasicInformation information, UIntPtr length);

    public static Dictionary<string, ulong> Measure(int processId) {
        var result = new Dictionary<string, ulong> {
            ["privateCommittedBytes"] = 0,
            ["mappedCommittedBytes"] = 0,
            ["imageCommittedBytes"] = 0,
            ["otherCommittedBytes"] = 0,
            ["privateWritableCommittedBytes"] = 0,
            ["privateExecutableCommittedBytes"] = 0,
            ["privateOtherProtectionCommittedBytes"] = 0,
            ["regionCount"] = 0,
        };
        var process = OpenProcess(QueryInformation, false, processId);
        if (process == IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
        try {
            var address = IntPtr.Zero;
            var informationSize = (UIntPtr)Marshal.SizeOf<MemoryBasicInformation>();
            while (true) {
                var queried = VirtualQueryEx(process, address, out var information, informationSize);
                if (queried == UIntPtr.Zero) break;
                var regionSize = information.RegionSize.ToUInt64();
                if (information.State == MemCommit && regionSize > 0) {
                    var key = information.Type == MemPrivate ? "privateCommittedBytes"
                        : information.Type == MemMapped ? "mappedCommittedBytes"
                        : information.Type == MemImage ? "imageCommittedBytes"
                        : "otherCommittedBytes";
                    result[key] += regionSize;
                    if (information.Type == MemPrivate) {
                        var protection = information.Protect & 0xff;
                        var writable = protection == 0x04 || protection == 0x08 || protection == 0x40 || protection == 0x80;
                        var executable = protection == 0x10 || protection == 0x20 || protection == 0x40 || protection == 0x80;
                        if (writable) result["privateWritableCommittedBytes"] += regionSize;
                        if (executable) result["privateExecutableCommittedBytes"] += regionSize;
                        if (!writable && !executable) result["privateOtherProtectionCommittedBytes"] += regionSize;
                    }
                    result["regionCount"]++;
                }
                var next = unchecked((ulong)address.ToInt64() + regionSize);
                if (next <= unchecked((ulong)address.ToInt64())) break;
                address = new IntPtr(unchecked((long)next));
            }
        }
        finally {
            CloseHandle(process);
        }
        return result;
    }
}
'@

function Get-Descendants {
    $all = @(Get-CimInstance Win32_Process)
    if (-not @($all | Where-Object { [int] $_.ProcessId -eq $RootPid })) {
        throw "Root PID $RootPid was not found."
    }
    $byParent = @{}
    foreach ($row in $all) {
        $parent = [int] $row.ParentProcessId
        if (-not $byParent.ContainsKey($parent)) { $byParent[$parent] = [System.Collections.Generic.List[object]]::new() }
        $byParent[$parent].Add($row)
    }
    $found = [System.Collections.Generic.HashSet[int]]::new()
    $queue = [System.Collections.Generic.Queue[int]]::new()
    [void] $found.Add($RootPid)
    $queue.Enqueue($RootPid)
    while ($queue.Count -gt 0) {
        $parent = $queue.Dequeue()
        foreach ($child in @($byParent[$parent])) {
            $childId = [int] $child.ProcessId
            if ($found.Add($childId)) { $queue.Enqueue($childId) }
        }
    }
    return @($all | Where-Object { $found.Contains([int] $_.ProcessId) })
}

function Get-Role {
    param([object] $Row)
    if ([int] $Row.ProcessId -eq $RootPid) { return 'native-shell' }
    if ($Row.Name -ne 'msedgewebview2.exe') { return 'other' }
    $command = ([string] $Row.CommandLine).ToLowerInvariant()
    if ($command -match '--type=renderer') { return 'renderer' }
    if ($command -match '--type=gpu-process') { return 'gpu-process' }
    if ($command -match 'network.mojom.networkservice') { return 'network-service' }
    if ($command -match 'storage.mojom.storageservice') { return 'storage-service' }
    if ($command -match 'crashpad') { return 'crashpad-handler' }
    return 'browser-or-utility'
}

$rows = foreach ($row in @(Get-Descendants)) {
    try {
        $process = Get-Process -Id ([int] $row.ProcessId) -ErrorAction Stop
        $memory = [TrackBVirtualMemory]::Measure([int] $row.ProcessId)
        [pscustomobject]@{
            pid = [int] $row.ProcessId
            role = Get-Role $row
            name = [string] $row.Name
            workingSetBytes = [long] $process.WorkingSet64
            privateBytes = [long] $process.PrivateMemorySize64
            privateCommittedBytes = [long] $memory.privateCommittedBytes
            privateWritableCommittedBytes = [long] $memory.privateWritableCommittedBytes
            privateExecutableCommittedBytes = [long] $memory.privateExecutableCommittedBytes
            privateOtherProtectionCommittedBytes = [long] $memory.privateOtherProtectionCommittedBytes
            mappedCommittedBytes = [long] $memory.mappedCommittedBytes
            imageCommittedBytes = [long] $memory.imageCommittedBytes
            otherCommittedBytes = [long] $memory.otherCommittedBytes
            committedRegionCount = [long] $memory.regionCount
        }
    }
    catch {
        # Processes can exit during a read-only snapshot; omit only that PID.
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    build = $ProcessName
    rootPid = $RootPid
    policy = 'Read-only VirtualQueryEx classification. Command lines are used locally for role labels and are not written.'
    processCount = @($rows).Count
    processes = @($rows)
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
[pscustomobject]@{ processCount = $result.processCount; outputPath = $OutputPath }
