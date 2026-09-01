def clip [] {
    let input = $in | into string
    match $nu.os-info.name {
        "windows" => { $input | clip.exe }
        "linux" => {
            if (which wl-copy | is-not-empty) {
                $input | wl-copy
            } else {
                $input | xclip -selection clipboard
            }
        }
        "macos" => { $input | pbcopy }
        _ => { error make { msg: "unsupported OS" } }
    }
}
alias c = clip
