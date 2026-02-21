param(
    [string]$SourceDir,
    [string]$GeneratedDir,
    [string]$MachineName,
    [string]$MachineNameFile
)

function Split-MachineNames {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return @()
    }

    return $Value `
        -split "[,;]" `
        | ForEach-Object { $_.Trim() } `
        | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

function Get-FilterValue {
    param(
        [string]$Text,
        [string]$Key
    )

    $pattern = "(?i)\b$Key\s*=\s*(?:""(?<value>[^""]+)""|'(?<value>[^']+)'|(?<value>[^\]\r\n]+))"
    $match = [regex]::Match($Text, $pattern)
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups["value"].Value.Trim()
}

function Get-FilterData {
    param([string]$Header)

    return @{
        Only = Get-FilterValue -Text $Header -Key "ONLY"
        Exclude = Get-FilterValue -Text $Header -Key "EXCLUDE"
    }
}

function Test-NameMatch {
    param(
        [string]$MachineNameValue,
        [string]$FilterValue
    )

    if ([string]::IsNullOrWhiteSpace($MachineNameValue)) {
        return $false
    }

    foreach ($candidate in (Split-MachineNames -Value $FilterValue)) {
        if ($MachineNameValue -ieq $candidate) {
            return $true
        }
    }

    return $false
}

function Test-IncludeBlock {
    param(
        [hashtable]$FilterData,
        [string]$MachineNameValue
    )

    if (-not [string]::IsNullOrWhiteSpace($FilterData.Only) -and -not (Test-NameMatch -MachineNameValue $MachineNameValue -FilterValue $FilterData.Only)) {
        return $false
    }

    if (-not [string]::IsNullOrWhiteSpace($FilterData.Exclude) -and (Test-NameMatch -MachineNameValue $MachineNameValue -FilterValue $FilterData.Exclude)) {
        return $false
    }

    return $true
}

function Transform-AutoBlocks {
    param(
        [string]$Text,
        [string]$MachineNameValue
    )

    if ([string]::IsNullOrWhiteSpace($Text) -or $Text -notmatch "(?i)#AUTO") {
        return $Text
    }

    $pattern = "(?ims)^[ \t]*(?:;[ \t]*)?#AUTO(?<header>[^\r\n]*)\r?\n(?<body>.*?)^[ \t]*(?:;[ \t]*)?#ENDAUTO[^\r\n]*\r?\n?"
    return [regex]::Replace(
        $Text,
        $pattern,
        {
            param($match)

            $filterData = Get-FilterData -Header $match.Groups["header"].Value
            if (Test-IncludeBlock -FilterData $filterData -MachineNameValue $MachineNameValue) {
                return $match.Groups["body"].Value
            }

            return ""
        }
    )
}

if (-not (Test-Path -LiteralPath $GeneratedDir -PathType Container)) {
    throw "Generated directory not found: $GeneratedDir"
}

$files = Get-ChildItem -LiteralPath $GeneratedDir -Recurse -File -Filter *.ahk
foreach ($file in $files) {
    $original = Get-Content -LiteralPath $file.FullName -Raw
    if ($null -eq $original) {
        continue
    }

    $updated = Transform-AutoBlocks -Text $original -MachineNameValue $MachineName
    if ($updated -ne $original) {
        Set-Content -LiteralPath $file.FullName -Value $updated -Encoding UTF8
    }
}
