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

    private static string RegionBucket(ulong regionSize) {
        if (regionSize < 64UL * 1024UL) return "Under64KiB";
        if (regionSize < 1024UL * 1024UL) return "64KiBTo1MiB";
        if (regionSize < 4UL * 1024UL * 1024UL) return "1MiBTo4MiB";
        if (regionSize < 16UL * 1024UL * 1024UL) return "4MiBTo16MiB";
        return "16MiBOrLarger";
    }

    private sealed class RegionCandidate {
        public ulong BaseAddress;
        public ulong AllocationBase;
        public ulong RegionSize;
        public uint AllocationProtect;
        public uint Protect;
    }

    private static ulong CountResidentBytes(IntPtr process, ulong baseAddress, ulong regionSize, ulong pageSize) {
        var pageCount = (regionSize + pageSize - 1) / pageSize;
        var residentPages = 0UL;
        var remaining = pageCount;
        var pageIndex = 0UL;
        var entrySize = Marshal.SizeOf(typeof(WorkingSetExInformation));
        while (remaining > 0) {
            var batch = (int)Math.Min(remaining, 2048UL);
            var buffer = Marshal.AllocHGlobal(entrySize * batch);
            try {
                for (var index = 0; index < batch; index++) {
                    var pageAddress = new IntPtr(unchecked((long)(baseAddress + (pageIndex + (ulong)index) * pageSize)));
                    var entry = new WorkingSetExInformation { VirtualAddress = pageAddress, VirtualAttributes = UIntPtr.Zero };
                    Marshal.StructureToPtr(entry, IntPtr.Add(buffer, index * entrySize), false);
                }
                if (QueryWorkingSetEx(process, buffer, entrySize * batch)) {
                    for (var index = 0; index < batch; index++) {
                        var entry = (WorkingSetExInformation)Marshal.PtrToStructure(IntPtr.Add(buffer, index * entrySize), typeof(WorkingSetExInformation));
                        if ((entry.VirtualAttributes.ToUInt64() & 1UL) != 0) residentPages++;
                    }
                }
            } finally {
                Marshal.FreeHGlobal(buffer);
            }
            remaining -= (ulong)batch;
            pageIndex += (ulong)batch;
        }
        return residentPages * pageSize;
    }

    public static List<Dictionary<string, object>> GetLargestPrivateWritableRegions(int processId, int limit) {
        var candidates = new List<RegionCandidate>();
        var process = OpenProcess(QueryInformation, false, processId);
        if (process == IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
        try {
            var address = IntPtr.Zero;
            var informationSize = (UIntPtr)Marshal.SizeOf(typeof(MemoryBasicInformation));
            while (true) {
                MemoryBasicInformation information;
                var queried = VirtualQueryEx(process, address, out information, informationSize);
                if (queried == UIntPtr.Zero) break;
                var regionSize = information.RegionSize.ToUInt64();
                if (information.State == MemCommit && regionSize > 0 && information.Type == MemPrivate && IsWritable(information.Protect)) {
                    candidates.Add(new RegionCandidate {
                        BaseAddress = unchecked((ulong)information.BaseAddress.ToInt64()),
                        AllocationBase = unchecked((ulong)information.AllocationBase.ToInt64()),
                        RegionSize = regionSize,
                        AllocationProtect = information.AllocationProtect,
                        Protect = information.Protect
                    });
                }
                var next = unchecked((ulong)address.ToInt64() + regionSize);
                if (next <= unchecked((ulong)address.ToInt64())) break;
                address = new IntPtr(unchecked((long)next));
            }
            candidates.Sort((left, right) => right.RegionSize.CompareTo(left.RegionSize));
            var result = new List<Dictionary<string, object>>();
            var pageSize = (ulong)Environment.SystemPageSize;
            var count = Math.Min(Math.Max(limit, 0), candidates.Count);
            for (var index = 0; index < count; index++) {
                var candidate = candidates[index];
                var residentBytes = CountResidentBytes(process, candidate.BaseAddress, candidate.RegionSize, pageSize);
                var row = new Dictionary<string, object>();
                row.Add("baseAddress", "0x" + candidate.BaseAddress.ToString("X"));
                row.Add("allocationBase", "0x" + candidate.AllocationBase.ToString("X"));
                row.Add("committedBytes", candidate.RegionSize);
                row.Add("residentBytes", residentBytes);
                row.Add("residentPages", residentBytes / pageSize);
                row.Add("allocationProtect", candidate.AllocationProtect);
                row.Add("protect", candidate.Protect);
                result.Add(row);
            }
            return result;
        } finally {
            CloseHandle(process);
        }
    }

    public static Dictionary<string, ulong> Measure(int processId) {
        var result = new Dictionary<string, ulong>();
        result["pageSize"] = (ulong)Environment.SystemPageSize;
        result["residentPages"] = 0;
        result["residentValidBytes"] = 0;
        result["committedBytes"] = 0;
        result["reservedBytes"] = 0;
        result["committedPrivateWritableBytes"] = 0;
        result["committedPrivateExecutableBytes"] = 0;
        result["committedPrivateOtherBytes"] = 0;
        result["committedMappedBytes"] = 0;
        result["committedImageBytes"] = 0;
        result["privateWritableResidentBytes"] = 0;
        result["privateExecutableResidentBytes"] = 0;
        result["privateOtherResidentBytes"] = 0;
        result["mappedResidentBytes"] = 0;
        result["imageResidentBytes"] = 0;
        result["otherResidentBytes"] = 0;
        result["sharedFlagResidentBytes"] = 0;
        result["privateWritableSharedFlagResidentBytes"] = 0;
        result["privateExecutableSharedFlagResidentBytes"] = 0;
        result["privateOtherSharedFlagResidentBytes"] = 0;
        result["queryRegionCount"] = 0;
        result["privateWritableRegionCount"] = 0;
        result["privateWritableUnder64KiBRegionCount"] = 0;
        result["privateWritable64KiBTo1MiBRegionCount"] = 0;
        result["privateWritable1MiBTo4MiBRegionCount"] = 0;
        result["privateWritable4MiBTo16MiBRegionCount"] = 0;
        result["privateWritable16MiBOrLargerRegionCount"] = 0;
        result["privateWritableUnder64KiBResidentBytes"] = 0;
        result["privateWritable64KiBTo1MiBResidentBytes"] = 0;
        result["privateWritable1MiBTo4MiBResidentBytes"] = 0;
        result["privateWritable4MiBTo16MiBResidentBytes"] = 0;
        result["privateWritable16MiBOrLargerResidentBytes"] = 0;
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
                if (regionSize > 0) {
                    if (information.State == MemCommit) {
                        result["committedBytes"] += regionSize;
                        if (information.Type == MemPrivate) {
                            if (IsWritable(information.Protect)) {
                                Add(result, "committedPrivateWritableBytes", regionSize);
                                var bucket = RegionBucket(regionSize);
                                Add(result, "privateWritable" + bucket + "RegionCount", 1);
                                Add(result, "privateWritableRegionCount", 1);
                            }
                            else if (IsExecutable(information.Protect)) Add(result, "committedPrivateExecutableBytes", regionSize);
                            else Add(result, "committedPrivateOtherBytes", regionSize);
                        } else if (information.Type == MemMapped) {
                            Add(result, "committedMappedBytes", regionSize);
                        } else if (information.Type == MemImage) {
                            Add(result, "committedImageBytes", regionSize);
                        }
                    } else if (information.State == 0x2000) {
                        result["reservedBytes"] += regionSize;
                    }
                }
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
                                    var shared = ((attributes >> 15) & 1UL) != 0;
                                    if (shared) result["sharedFlagResidentBytes"] += bytes;
                                    if (information.Type == MemPrivate) {
                                        if (IsWritable(information.Protect)) {
                                            Add(result, "privateWritableResidentBytes", bytes);
                                            Add(result, "privateWritable" + RegionBucket(regionSize) + "ResidentBytes", bytes);
                                            if (shared) Add(result, "privateWritableSharedFlagResidentBytes", bytes);
                                        } else if (IsExecutable(information.Protect)) {
                                            Add(result, "privateExecutableResidentBytes", bytes);
                                            if (shared) Add(result, "privateExecutableSharedFlagResidentBytes", bytes);
                                        } else {
                                            Add(result, "privateOtherResidentBytes", bytes);
                                            if (shared) Add(result, "privateOtherSharedFlagResidentBytes", bytes);
                                        }
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
$privateResidentBytes = [uint64]$memory.privateWritableResidentBytes + [uint64]$memory.privateExecutableResidentBytes + [uint64]$memory.privateOtherResidentBytes
$privateSharedFlagBytes = [uint64]$memory.privateWritableSharedFlagResidentBytes + [uint64]$memory.privateExecutableSharedFlagResidentBytes + [uint64]$memory.privateOtherSharedFlagResidentBytes
$memory['privateResidentBytes'] = $privateResidentBytes
$memory['privateSharedFlagResidentBytes'] = $privateSharedFlagBytes
$memory['uniquePrivateResidentBytes'] = if ($privateResidentBytes -ge $privateSharedFlagBytes) { $privateResidentBytes - $privateSharedFlagBytes } else { 0 }
$largestPrivateWritableRegions = @([TrackBResidentMemoryTypes]::GetLargestPrivateWritableRegions($ProcessId, 32))
$allocationBaseGroups = @($largestPrivateWritableRegions | Group-Object -Property { [string]$_.allocationBase } | ForEach-Object {
    [int64]$residentBytes = 0
    [int64]$committedBytes = 0
    foreach ($region in @($_.Group)) {
        $residentBytes += [int64]$region.residentBytes
        $committedBytes += [int64]$region.committedBytes
    }
    [pscustomobject]@{
        allocationBase = [string]$_.Name
        regionCount = $_.Count
        residentBytes = $residentBytes
        residentMiB = [math]::Round($residentBytes / 1MB, 3)
        committedBytes = $committedBytes
        committedMiB = [math]::Round($committedBytes / 1MB, 3)
    }
} | Sort-Object residentBytes -Descending)
$process = Get-Process -Id $ProcessId -ErrorAction Stop
$result = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    processId = $ProcessId
    role = $Role
    processName = $process.ProcessName
    workingSetBytes = [long]$process.WorkingSet64
    privateBytes = [long]$process.PrivateMemorySize64
    pageSource = 'VirtualQueryEx plus QueryWorkingSetEx; uniquePrivateResidentBytes excludes pages marked Shared by QueryWorkingSetEx within this process, but is not cross-process physical-page deduplication.'
    memory = $memory
    largestPrivateWritableRegions = $largestPrivateWritableRegions
    allocationBaseGroups = $allocationBaseGroups
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
    privateResidentMiB = [math]::Round($memory.privateResidentBytes / 1MB, 3)
    privateSharedFlagResidentMiB = [math]::Round($memory.privateSharedFlagResidentBytes / 1MB, 3)
    uniquePrivateResidentMiB = [math]::Round($memory.uniquePrivateResidentBytes / 1MB, 3)
    privateWritableRegionCount = $memory.privateWritableRegionCount
    privateWritableRegionBuckets = [pscustomobject]@{
        under64KiB = $memory.privateWritableUnder64KiBRegionCount
        '64KiBTo1MiB' = $memory.privateWritable64KiBTo1MiBRegionCount
        '1MiBTo4MiB' = $memory.privateWritable1MiBTo4MiBRegionCount
        '4MiBTo16MiB' = $memory.privateWritable4MiBTo16MiBRegionCount
        '16MiBOrLarger' = $memory.privateWritable16MiBOrLargerRegionCount
    }
    privateWritableResidentBucketsMiB = [pscustomobject]@{
        under64KiB = [math]::Round($memory.privateWritableUnder64KiBResidentBytes / 1MB, 3)
        '64KiBTo1MiB' = [math]::Round($memory.privateWritable64KiBTo1MiBResidentBytes / 1MB, 3)
        '1MiBTo4MiB' = [math]::Round($memory.privateWritable1MiBTo4MiBResidentBytes / 1MB, 3)
        '4MiBTo16MiB' = [math]::Round($memory.privateWritable4MiBTo16MiBResidentBytes / 1MB, 3)
        '16MiBOrLarger' = [math]::Round($memory.privateWritable16MiBOrLargerResidentBytes / 1MB, 3)
    }
    privateWritableSharedFlagResidentMiB = [math]::Round($memory.privateWritableSharedFlagResidentBytes / 1MB, 3)
    privateExecutableSharedFlagResidentMiB = [math]::Round($memory.privateExecutableSharedFlagResidentBytes / 1MB, 3)
    privateOtherSharedFlagResidentMiB = [math]::Round($memory.privateOtherSharedFlagResidentBytes / 1MB, 3)
    committedMiB = [math]::Round($memory.committedBytes / 1MB, 3)
    reservedMiB = [math]::Round($memory.reservedBytes / 1MB, 3)
    committedPrivateWritableMiB = [math]::Round($memory.committedPrivateWritableBytes / 1MB, 3)
    committedPrivateExecutableMiB = [math]::Round($memory.committedPrivateExecutableBytes / 1MB, 3)
    committedPrivateOtherMiB = [math]::Round($memory.committedPrivateOtherBytes / 1MB, 3)
    committedMappedMiB = [math]::Round($memory.committedMappedBytes / 1MB, 3)
    committedImageMiB = [math]::Round($memory.committedImageBytes / 1MB, 3)
    mappedResidentMiB = [math]::Round($memory.mappedResidentBytes / 1MB, 3)
    imageResidentMiB = [math]::Round($memory.imageResidentBytes / 1MB, 3)
    outputPath = $OutputPath
} | Format-List
