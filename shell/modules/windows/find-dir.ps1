function fcd {
    param(
        [string]$pattern
    )
    $dir = Get-ChildItem -Directory | Where-Object { $_.Name -like "*$pattern*" } | Select-Object -First 1
    if ($dir) {
        Set-Location $dir.FullName
    } else {
        Write-Host "No directory containing '$pattern' found"
    }
}

function web {
    fcd -pattern 'web'
}

function api {
    fcd -pattern 'api'
}
