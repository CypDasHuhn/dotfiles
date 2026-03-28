def histedit [] {
    let tmp = $"/tmp/histedit_(date now | format date '%Y%m%d_%H%M%S').txt"
    history | get command | to text | save $tmp
    nvim $tmp
    rm $tmp
}
