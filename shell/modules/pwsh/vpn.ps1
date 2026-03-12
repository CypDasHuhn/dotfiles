function Vpn {
   & $env:tools\vpn\cnct-i2g.ps1
}

function Rdp {
    param(
        [string]$Name
    )

    $files  = Get-ChildItem $env:rdp -Filter *.rdp

    if (-not $Name) {
        "Available RDP profiles:"
        $files.BaseName | Sort-Object
        return
    }

    $match = $files | Where-Object BaseName -eq $Name
    if (-not $match) {
        throw "No RDP profile named '$Name'. Run: Rdp   to list."
    }

    mstsc.exe $match.FullName
}
