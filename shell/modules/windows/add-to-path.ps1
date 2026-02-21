function Add-ToPath {
    param([string]$Dir)
    $current = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ($current -split ";" -contains $Dir) {
        Write-Host "$Dir is already in PATH"
        return
    }
    [System.Environment]::SetEnvironmentVariable("PATH", "$Dir;$current", "User")
    Write-Host "Added $Dir to PATH"
}
