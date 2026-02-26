# PSReadLine options

# Set-PSReadLineOption -PredictionSource History
# Set-PSReadLineOption -PredictionViewStyle ListView

# Import modules so they're active
# Import-Module Terminal-Icons
# Lazy load z - only imports on first use of z
# function z {
#     Import-Module z
#     z @args
# }
# Import-Module PSFzf
# Generate once, cache to file, source the cache

# $ompCache = "$env:TEMP\omp_init.ps1"
# if (!(Test-Path $ompCache) -or ((Get-Date) - (Get-Item $ompCache).LastWriteTime).TotalDays -gt 1) {
#     oh-my-posh init pwsh | Out-File $ompCache
# }
# . $ompCache
