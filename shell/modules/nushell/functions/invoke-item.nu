def invoke-item [path: string = "."] {
    if ("WSL_DISTRO_NAME" in $env) {
        ^wslview $path
    } else {
        match $nu.os-info.name {
            "windows" => { ^cmd /c start "" $path }
            "macos"   => { ^open $path }
            _         => { ^xdg-open $path }
        }
    }
}
alias ii = invoke-item
