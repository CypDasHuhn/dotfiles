function Set-GEnv {
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Value
    )

    [Environment]::SetEnvironmentVariable($Key, $Value, 'Machine')
}
