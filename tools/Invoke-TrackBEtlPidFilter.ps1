[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $EtlPath,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $PidManifestPath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
$dotnet = (Get-Command dotnet.exe -ErrorAction Stop).Source
$project = Join-Path (Split-Path -Parent $PSScriptRoot) 'benchmarks/private/TrackBEtlFilter/TrackBEtlFilter.csproj'
if (-not (Test-Path -LiteralPath $project -PathType Leaf)) {
    throw "The ETL filter project was not found: $project"
}

$resolvedEtl = (Resolve-Path -LiteralPath $EtlPath).Path
$resolvedManifest = (Resolve-Path -LiteralPath $PidManifestPath).Path
$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
New-Item -ItemType Directory -Path (Split-Path -Parent $resolvedOutput) -Force | Out-Null

& $dotnet run --project $project --no-build -- $resolvedEtl $resolvedManifest $resolvedOutput
if ($LASTEXITCODE -ne 0) {
    throw "The PID-filtered ETL decoder failed with exit code $LASTEXITCODE."
}
