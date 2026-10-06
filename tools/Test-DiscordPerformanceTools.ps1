[CmdletBinding()]
param(
    [string] $ToolsPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'tools')
)

$resolvedToolsPath = (Resolve-Path -LiteralPath $ToolsPath -ErrorAction Stop).Path
$scripts = @(Get-ChildItem -LiteralPath $resolvedToolsPath -Filter '*.ps1' -File | Where-Object Name -ne (Split-Path -Leaf $PSCommandPath))
if ($scripts.Count -eq 0) {
    throw "No PowerShell tools found in $resolvedToolsPath."
}

$failures = @()
foreach ($script in $scripts) {
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $script.FullName,
        [ref]$null,
        [ref]$parseErrors
    ) | Out-Null
    if ($parseErrors.Count -gt 0) {
        $messages = $parseErrors | ForEach-Object { $_.Message }
        $failures += "${($script.Name)}: $($messages -join '; ')"
    }
}

if ($failures.Count -gt 0) {
    throw ($failures -join [Environment]::NewLine)
}

[pscustomobject]@{
    toolCount = $scripts.Count
    parsed = $true
    toolsPath = $resolvedToolsPath
}
