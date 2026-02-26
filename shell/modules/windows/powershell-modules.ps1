# PSReadLine options
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# Import modules so they're active
Import-Module Terminal-Icons
Import-Module z
Import-Module PSFzf

# Oh My Posh prompt (the exact command it gives you after install)
oh-my-posh init pwsh | Invoke-Expression
