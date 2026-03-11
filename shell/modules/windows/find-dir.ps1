function fcd {
  param(
      [string]$pattern,
      [int]$depth = 1
  )
  $dir = Get-ChildItem -Directory -Depth $depth |
      Where-Object { $_.Name -like "*$pattern*" } |
      Select-Object -First 1

  if ($dir) {
      Set-Location $dir.FullName
      Write-Host "-> $($dir.FullName)" -ForegroundColor Green
      return $true
  }

  Write-Host "No directory matching '$pattern' found" -ForegroundColor Red
  return $false
}

function web {
    if (-not (fcd 'web')) { fcd 'frontend' }
}
function api {
    fcd -pattern 'api'
}
