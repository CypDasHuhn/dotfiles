def make-symlink [target: path, link: path] {
    let resolved_link = if ($link | path type) == "dir" {
        $link | path join ($target | path basename)
    } else {
        $link
    }
    if $nu.os-info.name == "windows" {
        ^powershell -Command $"New-Item -ItemType SymbolicLink -Path \"($resolved_link)\" -Target \"($target)\""    } else {
        ^ln -s $target $resolved_link
    }
}

alias ln = make-symlink
