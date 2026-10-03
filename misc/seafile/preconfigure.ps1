# Preconfigure the Seafile Windows sync client for this server.
#
# Writes %USERPROFILE%\seafile.ini so the login wizard is skipped. The password
# is read from a file (not a command-line argument) so it never shows up in the
# process list. Which library to sync still has to be picked in the GUI.
param(
    [Parameter(Mandatory = $true)][string]$Server,
    [Parameter(Mandatory = $true)][string]$Username,
    [Parameter(Mandatory = $true)][string]$PasswordFile,
    [Parameter(Mandatory = $true)][string]$Directory
)

$ErrorActionPreference = 'Stop'

$password = (Get-Content -LiteralPath $PasswordFile -Raw).Trim()
$body = @{ username = $Username; password = $password }
$token = (Invoke-RestMethod -Method Post -Uri ($Server.TrimEnd('/') + '/api2/auth-token/') -Body $body).token
if (-not $token) {
    throw 'Failed to obtain an auth token'
}

$ini = Join-Path $env:USERPROFILE 'seafile.ini'
Set-Content -LiteralPath $ini -Encoding ASCII -Value @(
    '[preconfigure]'
    "PreconfigureServerAddr = $Server"
    "PreconfigureUsername = $Username"
    "PreconfigureUserToken = $token"
    "PreconfigureDirectory = $Directory"
    'HideConfigurationWizard = 1'
    'PreconfigureServerAddrOnly = 1'
)

Write-Output $ini
