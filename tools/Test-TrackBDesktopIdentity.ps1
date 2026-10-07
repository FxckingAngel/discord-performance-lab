[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $EnvironmentReport
)

$ErrorActionPreference = 'Stop'
$report = Get-Content -LiteralPath $EnvironmentReport -Raw | ConvertFrom-Json
$environment = $report.environment
if (-not $environment) { throw 'Environment report is missing environment data.' }

$userAgent = [string]$environment.userAgent
if ($userAgent -notmatch 'discord/') { throw 'Track B user-agent does not contain the audited Discord identity.' }
if ($userAgent -notmatch 'Electron/') { throw 'Track B user-agent does not contain the audited desktop runtime identity.' }
if ([string]$environment.platform -ne 'Win32') { throw "Unexpected platform: $($environment.platform)" }

$native = $environment.globalPresence.DiscordNative
if ($native.present -ne $false -or [string]$native.type -ne 'undefined') {
    throw 'Normal identity report exposes DiscordNative before a complete audited capability surface exists.'
}

$groups = @($environment.discordNativeGroups.psobject.Properties | Where-Object { $_.Value.present -eq $true })
if ($groups.Count -gt 0) {
    throw "Normal identity report exposes native capability groups without production activation review: $(($groups.Name -join ', '))."
}

[pscustomobject]@{
    result = 'PASS'
    policy = 'Identity is desktop-shaped, but unsupported native capabilities remain unavailable.'
    userAgentDesktopIdentity = $true
    platform = [string]$environment.platform
    discordNativeExposed = $false
    exposedNativeGroupCount = 0
    officialDiscordTouched = $false
} | ConvertTo-Json -Depth 4
