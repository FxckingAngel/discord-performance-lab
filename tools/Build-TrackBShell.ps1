[CmdletBinding()]
param(
    [string] $DotnetPath = (Join-Path (Split-Path -Parent $PSScriptRoot) '.tools\dotnet\dotnet.exe'),
    [string] $OutputPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b\discord-shell\bin\Verified')
)

$root = Split-Path -Parent $PSScriptRoot
$projectFiles = @('KoroneDiscordShell.csproj', 'Program.cs', 'MainForm.cs', 'NativeHostProbe.cs', 'app.manifest')
$resolvedDotnet = (Resolve-Path -LiteralPath $DotnetPath -ErrorAction Stop).Path
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('trackb-build-' + [guid]::NewGuid().ToString('N'))
$tempProject = Join-Path $tempRoot 'KoroneDiscordShell.csproj'
$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)

New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
    foreach ($file in $projectFiles) {
        Copy-Item -LiteralPath (Join-Path $root "track-b\discord-shell\$file") -Destination $tempRoot -Force
    }

    & $resolvedDotnet restore $tempProject
    if ($LASTEXITCODE -ne 0) { throw "dotnet restore failed with exit code $LASTEXITCODE." }

    New-Item -ItemType Directory -Path $resolvedOutput -Force | Out-Null
    & $resolvedDotnet publish $tempProject --configuration Release --no-restore --output $resolvedOutput
    if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed with exit code $LASTEXITCODE." }

    [pscustomobject]@{
        project = $tempProject
        output = $resolvedOutput
        executable = Join-Path $resolvedOutput 'KoroneDiscordShell.exe'
        result = 'PASS'
    }
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
