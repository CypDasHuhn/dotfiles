function repeat($n, [scriptblock]$cmd) { 1..$n | ForEach-Object { & $cmd } }
Set-Alias re repeat
