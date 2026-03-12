function Set-GEnv {
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Value
    )

    [Environment]::SetEnvironmentVariable($Key, $Value, 'Machine')
}

function Set-Path {
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Dir
    )

    $Dir = (Resolve-Path $Dir).Path

    if ($env:PATH -split [IO.Path]::PathSeparator -notcontains $Dir) {
        $env:PATH = $Dir + [IO.Path]::PathSeparator + $env:PATH
        Write-Host "Added to PATH: $Dir"
    } else {
        Write-Host "Already in PATH: $Dir"
    }
}
