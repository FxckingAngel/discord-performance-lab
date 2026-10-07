[CmdletBinding()]
param(
    [string] $DotnetPath,
    [string] $OutputPath
)

$root = Split-Path -Parent $PSScriptRoot
$defaultSdkCandidates = @(
    (Join-Path $root '.tools\dotnet\dotnet.exe'),
    (Join-Path $root '.dotnet\dotnet.exe')
)
if ([string]::IsNullOrWhiteSpace($DotnetPath)) {
    $DotnetPath = @($defaultSdkCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1)[0]
    if ([string]::IsNullOrWhiteSpace($DotnetPath)) {
        $dotnetCommand = Get-Command dotnet.exe -ErrorAction SilentlyContinue
        if ($dotnetCommand) { $DotnetPath = $dotnetCommand.Source }
    }
}
if ([string]::IsNullOrWhiteSpace($DotnetPath)) {
    throw 'No .NET SDK was found. Pass -DotnetPath or install the portable SDK under .tools\dotnet or .dotnet.'
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $root 'track-b\discord-shell\bin\Verified'
}
$projectFiles = @(
    'KoroneDiscordShell.csproj',
    'Program.cs',
    'MainForm.cs',
    'NativeHostProbe.cs',
    'ClipboardHostObject.cs',
    'FileDialogHostObject.cs',
    'PowerMonitorHostObject.cs',
    'ProcessUtilsHostObject.cs',
    'SafeStorageHostObject.cs',
    'WindowsClipboardBackend.cs',
    'app.manifest'
)
$resolvedDotnet = (Resolve-Path -LiteralPath $DotnetPath -ErrorAction Stop).Path
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('trackb-build-' + [guid]::NewGuid().ToString('N'))
$tempProject = Join-Path $tempRoot 'KoroneDiscordShell.csproj'
$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)

New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
    foreach ($file in $projectFiles) {
        Copy-Item -LiteralPath (Join-Path $root "track-b\discord-shell\$file") -Destination $tempRoot -Force
    }
    Copy-Item -LiteralPath (Join-Path $root 'track-b\discord-shell\web') -Destination (Join-Path $tempRoot 'web') -Recurse -Force

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
