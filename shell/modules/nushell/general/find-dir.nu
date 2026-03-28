def --env fcd [
    pattern: string,
    --depth: int = 1
] {
    let matches = (ls | where type == "dir" | where name =~ ("(?i)" + $pattern)) 
    if ($matches | is-empty) {
        error make { msg: $"(ansi red)No directory matching '($pattern)' found(ansi reset)"}
    }
    let dir = ($matches | first | get name)
    cd $dir
}

def --env web [] {
    try {
        fcd "web"
    } catch {
        fcd "frontend"
    }
}

alias api = fcd "api"
