[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $ProcessId,

    [ValidateNotNullOrEmpty()]
    [string] $Role = 'renderer',

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-resident-memory-types-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class TrackBResidentMemoryTypes {
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

    [StructLayout(LayoutKind.Sequential)]
    private struct WorkingSetExInformation {
        public IntPtr VirtualAddress;
        public UIntPtr VirtualAttributes;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(uint access, bool inheritHandle, int processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern UIntPtr VirtualQueryEx(IntPtr process, IntPtr address, out MemoryBasicInformation information, UIntPtr length);

    [DllImport("psapi.dll", SetLastError = true)]
    private static extern bool QueryWorkingSetEx(IntPtr process, IntPtr buffer, int size);

    private static bool IsWritable(uint protection) {
        var value = protection & 0xff;
        return value == 0x04 || value == 0x08 || value == 0x40 || value == 0x80;
    }

    private static bool IsExecutable(uint protection) {
        var value = protection & 0xff;
        return value == 0x10 || value == 0x20 || value == 0x40 || value == 0x80;
    }

    private static void Add(Dictionary<string, ulong> result, string key, ulong value) {
        result[key] = result[key] + value;
    }

    public static Dictionary<string, ulong> Measure(int processId) {
        var result = new Dictionary<string, ulong>();
        result["pageSize"] = (ulong)Environment.SystemPageSize;
        result["residentPages"] = 0;
        result["residentValidBytes"] = 0;
        result["privateWritableResidentBytes"] = 0;
        result["privateExecutableResidentBytes"] = 0;
        result["privateOtherResidentBytes"] = 0;
        result["mappedResidentBytes"] = 0;
        result["imageResidentBytes"] = 0;
        result["otherResidentBytes"] = 0;
        result["sharedFlagResidentBytes"] = 0;
        result["queryRegionCount"] = 0;
        var process = OpenProcess(QueryInformation, false, processId);
        if (process == IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
        try {
            var address = IntPtr.Zero;
            var informationSize = (UIntPtr)Marshal.SizeOf(typeof(MemoryBasicInformation));
            var pageSize = (ulong)Environment.SystemPageSize;
            while (true) {
                MemoryBasicInformation information;
                var queried = VirtualQueryEx(process, address, out information, informationSize);
                if (queried == UIntPtr.Zero) break;
                var regionSize = information.RegionSize.ToUInt64();
                if (information.State == MemCommit && regionSize > 0) {
                    result["queryRegionCount"]++;
                    var pageCount = (regionSize + pageSize - 1) / pageSize;
                    var remaining = pageCount;
                    var pageIndex = 0UL;
                    var entrySize = Marshal.SizeOf(typeof(WorkingSetExInformation));
                    while (remaining > 0) {
                        var batch = (int)Math.Min(remaining, 2048UL);
                        var buffer = Marshal.AllocHGlobal(entrySize * batch);
                        try {
                            for (var index = 0; index < batch; index++) {
                                var pageAddress = new IntPtr(address.ToInt64() + (long)((pageIndex + (ulong)index) * pageSize));
                                var entry = new WorkingSetExInformation { VirtualAddress = pageAddress, VirtualAttributes = UIntPtr.Zero };
                                Marshal.StructureToPtr(entry, IntPtr.Add(buffer, index * entrySize), false);
                            }
                            if (QueryWorkingSetEx(process, buffer, entrySize * batch)) {
                                for (var index = 0; index < batch; index++) {
                                    var entry = (WorkingSetExInformation)Marshal.PtrToStructure(IntPtr.Add(buffer, index * entrySize), typeof(WorkingSetExInformation));
                                    var attributes = entry.VirtualAttributes.ToUInt64();
                                    if ((attributes & 1UL) == 0) continue;
                                    var bytes = pageSize;
                                    result["residentPages"]++;
                                    result["residentValidBytes"] += bytes;
                                    if (((attributes >> 15) & 1UL) != 0) result["sharedFlagResidentBytes"] += bytes;
                                    if (information.Type == MemPrivate) {
                                        if (IsWritable(information.Protect)) Add(result, "privateWritableResidentBytes", bytes);
                                        else if (IsExecutable(information.Protect)) Add(result, "privateExecutableResidentBytes", bytes);
                                        else Add(result, "privateOtherResidentBytes", bytes);
                                    } else if (information.Type == MemMapped) Add(result, "mappedResidentBytes", bytes);
                                    else if (information.Type == MemImage) Add(result, "imageResidentBytes", bytes);
                                    else Add(result, "otherResidentBytes", bytes);
                                }
                            }
                        } finally {
                            Marshal.FreeHGlobal(buffer);
                        }
                        remaining -= (ulong)batch;
                        pageIndex += (ulong)batch;
                    }
                }
                var next = unchecked((ulong)address.ToInt64() + regionSize);
                if (next <= unchecked((ulong)address.ToInt64())) break;
                address = new IntPtr(unchecked((long)next));
            }
        } finally {
            CloseHandle(process);
        }
        return result;
    }
}
'@

$memory = [TrackBResidentMemoryTypes]::Measure($ProcessId)
$process = Get-Process -Id $ProcessId -ErrorAction Stop
$result = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    processId = $ProcessId
    role = $Role
    processName = $process.ProcessName
    workingSetBytes = [long]$process.WorkingSet64
    privateBytes = [long]$process.PrivateMemorySize64
    pageSource = 'VirtualQueryEx plus QueryWorkingSetEx; resident classifications are per-process and not cross-process physical-page deduplication.'
    memory = $memory
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
[pscustomobject]@{
    processId = $ProcessId
    role = $Role
    residentMiB = [math]::Round($memory.residentValidBytes / 1MB, 3)
    privateWritableResidentMiB = [math]::Round($memory.privateWritableResidentBytes / 1MB, 3)
    privateExecutableResidentMiB = [math]::Round($memory.privateExecutableResidentBytes / 1MB, 3)
    privateOtherResidentMiB = [math]::Round($memory.privateOtherResidentBytes / 1MB, 3)
    mappedResidentMiB = [math]::Round($memory.mappedResidentBytes / 1MB, 3)
    imageResidentMiB = [math]::Round($memory.imageResidentBytes / 1MB, 3)
    outputPath = $OutputPath
} | Format-List
