param(
    [string]$SourceDir,
    [string]$GeneratedDir,
    [string]$MachineName,
    [string]$MachineNameFile
)

if (-not (Test-Path -LiteralPath $GeneratedDir -PathType Container)) {
    throw "Generated directory not found: $GeneratedDir"
}

function Get-RelativePath {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    $fullBasePath = [System.IO.Path]::GetFullPath($BasePath)
    if (-not $fullBasePath.EndsWith("\")) {
        $fullBasePath += "\"
    }

    $baseUri = New-Object System.Uri($fullBasePath)
    $targetUri = New-Object System.Uri([System.IO.Path]::GetFullPath($TargetPath))
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace("/", "\")
}

$outputFile = Join-Path $GeneratedDir "home.ahk"

$inputFiles = Get-ChildItem -LiteralPath $GeneratedDir -Recurse -File -Filter *.ahk | Where-Object {
    $_.FullName -ine $outputFile
} | Sort-Object FullName

$output = @()
$output += "; Auto-generated file - DO NOT EDIT MANUALLY"
$output += "; Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$output += "; Machine: $MachineName"
$output += ""
$output += "#Requires AutoHotkey v2.0"
$output += "#SingleInstance Force"
$output += ""

foreach ($file in $inputFiles) {
    $relativePath = Get-RelativePath -BasePath $GeneratedDir -TargetPath $file.FullName
    $output += "#Include `"$relativePath`""
}

$output | Set-Content -LiteralPath $outputFile -Encoding UTF8
