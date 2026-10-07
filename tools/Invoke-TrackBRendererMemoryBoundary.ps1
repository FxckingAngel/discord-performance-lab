[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'KoroneDiscordShell',

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory
)

$root = Split-Path -Parent $PSScriptRoot
$virtualTool = Join-Path $PSScriptRoot 'Measure-TrackBVirtualMemoryTypes.ps1'
$residentTool = Join-Path $PSScriptRoot 'Measure-TrackBResidentMemoryTypes.ps1'
foreach ($tool in @($virtualTool, $residentTool)) {
    if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) { throw "Required tool was not found: $tool" }
}

$rootProcess = Get-CimInstance Win32_Process -Filter "ProcessId=$RootPid" -ErrorAction SilentlyContinue
if (-not $rootProcess -or $rootProcess.Name -ne "$ProcessName.exe") {
    throw "Root PID $RootPid is not a live $ProcessName process."
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$virtualPath = Join-Path $OutputDirectory 'virtual-types.json'
$residentPath = Join-Path $OutputDirectory 'renderer-resident-types.json'
$manifestPath = Join-Path $OutputDirectory 'boundary-capture.json'
$pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source

& $pwsh -NoProfile -File $virtualTool -RootPid $RootPid -ProcessName $ProcessName -OutputPath $virtualPath | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Virtual-memory classification failed with exit code $LASTEXITCODE." }
$virtual = Get-Content -Raw -LiteralPath $virtualPath | ConvertFrom-Json
$renderer = @($virtual.processes | Where-Object role -eq 'renderer' | Select-Object -First 1)
if ($renderer.Count -ne 1) { throw "Expected exactly one renderer in the rooted process tree; found $($renderer.Count)." }

& $pwsh -NoProfile -File $residentTool -ProcessId ([int] $renderer.pid) -Role renderer -OutputPath $residentPath | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Resident-memory classification failed with exit code $LASTEXITCODE." }

[pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    rootPid = $RootPid
    rendererPid = [int] $renderer.pid
    processName = $ProcessName
    processCount = [int] $virtual.processCount
    virtualTypesPath = (Resolve-Path -LiteralPath $virtualPath).Path
    rendererResidentTypesPath = (Resolve-Path -LiteralPath $residentPath).Path
    policy = 'Read-only sequential classification. Renderer PID is selected from the rooted process tree before resident measurement; categories are not cross-process physical-page deduplicated.'
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8

Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
