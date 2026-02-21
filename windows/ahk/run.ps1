param(
    [string]$SourceDir = ".",
    [string]$GeneratedDir = ".\generated",
    [string]$MappersDir = ".\mappers",
    [string]$GeneratorsDir = ".\generators",
    [string]$MachineNameFile = "..\ps\.machine-name.local"
)

$ErrorActionPreference = "Stop"

function Resolve-LocalPath {
    param(
        [string]$BasePath,
        [string]$PathValue
    )

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return [System.IO.Path]::GetFullPath($PathValue)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $PathValue))
}

function Test-IsUnderPath {
    param(
        [string]$Path,
        [string]$ParentPath
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd("\")
    $fullParent = [System.IO.Path]::GetFullPath($ParentPath).TrimEnd("\")

    return $fullPath.StartsWith($fullParent + "\", [System.StringComparison]::OrdinalIgnoreCase) -or $fullPath.Equals($fullParent, [System.StringComparison]::OrdinalIgnoreCase)
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

function Get-MachineName {
    param([string]$MachineNameFilePath)

    if (Test-Path -LiteralPath $MachineNameFilePath -PathType Leaf) {
        $lines = Get-Content -LiteralPath $MachineNameFilePath
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if (-not [string]::IsNullOrWhiteSpace($trimmed) -and -not $trimmed.StartsWith("#")) {
                return $trimmed
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) {
        return $env:COMPUTERNAME
    }

    return ""
}

function Invoke-ScriptSet {
    param(
        [string]$DirectoryPath,
        [string]$SourceDirPath,
        [string]$GeneratedDirPath,
        [string]$MachineName,
        [string]$MachineNameFilePath
    )

    if (-not (Test-Path -LiteralPath $DirectoryPath -PathType Container)) {
        return
    }

    $scripts = Get-ChildItem -LiteralPath $DirectoryPath -Filter *.ps1 | Sort-Object Name
    foreach ($script in $scripts) {
        & $script.FullName `
            -SourceDir $SourceDirPath `
            -GeneratedDir $GeneratedDirPath `
            -MachineName $MachineName `
            -MachineNameFile $MachineNameFilePath
    }
}

function Ensure-StartupLink {
    param(
        [string]$GeneratedDirPath
    )

    $startupDir = $env:startup
    if ([string]::IsNullOrWhiteSpace($startupDir)) {
        throw "Required environment variable 'startup' is not set."
    }

    if (-not (Test-Path -LiteralPath $startupDir -PathType Container)) {
        throw "Startup directory from `$env:startup does not exist: $startupDir"
    }

    $homeFile = Join-Path $GeneratedDirPath "home.ahk"
    if (-not (Test-Path -LiteralPath $homeFile -PathType Leaf)) {
        throw "Generated home file not found: $homeFile"
    }

    $startupLinkPath = Join-Path $startupDir "home.ahk"
    if (Test-Path -LiteralPath $startupLinkPath) {
        Remove-Item -LiteralPath $startupLinkPath -Force
    }

    try {
        New-Item -ItemType SymbolicLink -Path $startupLinkPath -Target $homeFile -Force | Out-Null
    } catch {
        try {
            New-Item -ItemType HardLink -Path $startupLinkPath -Target $homeFile -Force | Out-Null
        } catch {
            throw "Failed to create startup link at '$startupLinkPath'. $($_.Exception.Message)"
        }
    }

    return $startupLinkPath
}

$root = [System.IO.Path]::GetFullPath($PSScriptRoot)
$resolvedSourceDir = Resolve-LocalPath -BasePath $root -PathValue $SourceDir
$resolvedGeneratedDir = Resolve-LocalPath -BasePath $root -PathValue $GeneratedDir
$resolvedMappersDir = Resolve-LocalPath -BasePath $root -PathValue $MappersDir
$resolvedGeneratorsDir = Resolve-LocalPath -BasePath $root -PathValue $GeneratorsDir
$resolvedMachineNameFile = Resolve-LocalPath -BasePath $root -PathValue $MachineNameFile

if (-not (Test-Path -LiteralPath $resolvedGeneratedDir -PathType Container)) {
    New-Item -Path $resolvedGeneratedDir -ItemType Directory -Force | Out-Null
}

Get-ChildItem -LiteralPath $resolvedGeneratedDir -Force | Remove-Item -Recurse -Force

$sourceFiles = Get-ChildItem -LiteralPath $resolvedSourceDir -Recurse -File -Filter *.ahk | Where-Object {
    -not (Test-IsUnderPath -Path $_.FullName -ParentPath $resolvedGeneratedDir) -and
    -not (Test-IsUnderPath -Path $_.FullName -ParentPath $resolvedMappersDir) -and
    -not (Test-IsUnderPath -Path $_.FullName -ParentPath $resolvedGeneratorsDir)
}

foreach ($file in $sourceFiles) {
    $relativePath = Get-RelativePath -BasePath $resolvedSourceDir -TargetPath $file.FullName
    $outputPath = Join-Path $resolvedGeneratedDir $relativePath
    $outputDir = Split-Path -Parent $outputPath

    if (-not (Test-Path -LiteralPath $outputDir -PathType Container)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    Copy-Item -LiteralPath $file.FullName -Destination $outputPath -Force
}

$machineName = Get-MachineName -MachineNameFilePath $resolvedMachineNameFile

Invoke-ScriptSet `
    -DirectoryPath $resolvedMappersDir `
    -SourceDirPath $resolvedSourceDir `
    -GeneratedDirPath $resolvedGeneratedDir `
    -MachineName $machineName `
    -MachineNameFilePath $resolvedMachineNameFile

$generatorScripts = @()
if (Test-Path -LiteralPath $resolvedGeneratorsDir -PathType Container) {
    $generatorScripts = Get-ChildItem -LiteralPath $resolvedGeneratorsDir -Filter *.ps1 | Sort-Object Name
}

$homeGenerators = @($generatorScripts | Where-Object { $_.BaseName -ieq "home" })
$otherGenerators = @($generatorScripts | Where-Object { $_.BaseName -ine "home" })

foreach ($script in $otherGenerators + $homeGenerators) {
    & $script.FullName `
        -SourceDir $resolvedSourceDir `
        -GeneratedDir $resolvedGeneratedDir `
        -MachineName $machineName `
        -MachineNameFile $resolvedMachineNameFile
}

$startupLink = Ensure-StartupLink -GeneratedDirPath $resolvedGeneratedDir

Write-Host "AHK generation complete." -ForegroundColor Green
Write-Host "Source:    $resolvedSourceDir"
Write-Host "Generated: $resolvedGeneratedDir"
Write-Host "Machine:   $machineName"
Write-Host "Startup:   $startupLink"
