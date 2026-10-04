def clip [] {
    let input = $in | into string
    if (which pbcopy | is-not-empty) {
        $input | pbcopy
    } else if (which clip.exe | is-not-empty) {
        $input | clip.exe
    } else if (($env.WAYLAND_DISPLAY? | is-not-empty) and (which wl-copy | is-not-empty)) {
        $input | wl-copy
    } else if (($env.DISPLAY? | is-not-empty) and (which xclip | is-not-empty)) {
        $input | xclip -selection clipboard
    } else {
        let b64 = $input | encode base64
        print -n $"(char -i 27)]52;c;($b64)(char -i 7)"
    }
}
alias c = clip
