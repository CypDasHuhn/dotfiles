function fcd {
    param(
        [string[]]$patterns,
        [int]$depth = 1
    )
    foreach ($pattern in $patterns) {
        $dir = Get-ChildItem -Directory -Depth $depth |
            Where-Object { $_.Name -like "*$pattern*" } |
            Select-Object -First 1
        if ($dir) {
            Set-Location $dir.FullName
            Write-Host "-> $($dir.FullName)" -ForegroundColor Green
        } else {
            Write-Host "No directory matching '$pattern' found" -ForegroundColor Red
            return
        }
    }
}
function web {
    fcd -pattern 'web'
}

function api {
    fcd -pattern 'api'
}
