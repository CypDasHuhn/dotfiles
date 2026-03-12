function Clear-NGENQueue {
	Write-Host Running NGEN compile for each applicable version. -ForegroundColor Green
	$NgenPath = Get-ChildItem -Path $Env:SystemRoot'\Microsoft.NET' -Recurse "ngen.exe" | % {$_.FullName}
	foreach ($element in $NgenPath) {
		Write-Host "Running .NET Optimization in $element";
		Start-Process -wait $element -ArgumentList "ExecuteQueuedItems"
	}
}
