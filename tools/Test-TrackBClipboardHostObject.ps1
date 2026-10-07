Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Run this isolated C# harness with pwsh 7 or newer.'
}

$assemblyPath = Join-Path $PSScriptRoot '..\track-b\discord-shell\bin\Release\net8.0-windows\KoroneDiscordShell.dll'
if (-not (Test-Path -LiteralPath $assemblyPath -PathType Leaf)) {
    throw "Build the shell before running this focused test: $assemblyPath"
}

Add-Type -Path ([IO.Path]::GetFullPath($assemblyPath))

function Assert-Equal {
    param(
        [Parameter(Mandatory)]$Actual,
        [Parameter(Mandatory)]$Expected,
        [Parameter(Mandatory)][string]$Name
    )

    if ($Actual -ne $Expected) {
        throw "$Name expected '$Expected' but received '$Actual'."
    }
}

$backend = [KoroneDiscordShell.SyntheticClipboardBackend]::new()
$clipboard = [KoroneDiscordShell.ClipboardHostObject]::new($backend)

$clipboard.Copy('synthetic clipboard text')
Assert-Equal -Actual $clipboard.Read() -Expected 'synthetic clipboard text' -Name 'copy/read'
Assert-Equal -Actual $backend.CopyCommandCount -Expected 0 -Name 'copy command count after text copy'
Assert-Equal -Actual $clipboard.HasMixedContent() -Expected $false -Name 'mixed content without image'

$syntheticImage = [byte[]](0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
$clipboard.CopyImage($syntheticImage, 'synthetic://image')
Assert-Equal -Actual $backend.ImageBytes.Length -Expected $syntheticImage.Length -Name 'image byte count'
Assert-Equal -Actual $backend.ImageSource -Expected 'synthetic://image' -Name 'image source'
Assert-Equal -Actual $clipboard.HasMixedContent() -Expected $false -Name 'image-only content'
$imageByteCount = $backend.ImageBytes.Length

$backend.SeedMixedContent('synthetic mixed text', $syntheticImage, 'synthetic://image')
Assert-Equal -Actual $clipboard.HasMixedContent() -Expected $true -Name 'mixed content with image and text'

$clipboard.CopyFile('C:\synthetic\clipboard-test.txt')
Assert-Equal -Actual $backend.FilePath -Expected 'C:\synthetic\clipboard-test.txt' -Name 'file path'

$clipboard.Copy('')
$clipboard.Copy($null)
$clipboard.Cut()
$clipboard.Paste()
Assert-Equal -Actual $backend.CopyCommandCount -Expected 2 -Name 'empty copy command count'
Assert-Equal -Actual $backend.CutCommandCount -Expected 1 -Name 'cut command count'
Assert-Equal -Actual $backend.PasteCommandCount -Expected 1 -Name 'paste command count'

[ordered]@{
    syntheticOnly = $true
    realSystemClipboardAccessed = $false
    userClipboardRead = $false
    userClipboardOverwritten = $false
    methods = @('copy', 'copyImage', 'copyFile', 'cut', 'paste', 'read', 'hasMixedContent')
    copyRead = $clipboard.Read()
    imageBytes = $imageByteCount
    filePathRecorded = $backend.FilePath
    copyCommandCount = $backend.CopyCommandCount
    cutCommandCount = $backend.CutCommandCount
    pasteCommandCount = $backend.PasteCommandCount
    mixedContent = $clipboard.HasMixedContent()
} | ConvertTo-Json -Compress
