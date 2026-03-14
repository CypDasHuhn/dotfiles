# Find and cd into a directory matching a pattern (inspired by find-dir.ps1)
def fcd [
    pattern: string,
    --depth: int = 1
] {
    let matches = (ls | where type == "dir" | where name =~ $pattern)
    if ($matches | is-empty) {
        print $"(ansi red)No directory matching '($pattern)' found(ansi reset)"
        return false
    }
    let dir = ($matches | first | get name)
    cd $dir
    print $"(ansi green)-> ($dir)(ansi reset)"
    true
}

def web [] {
    if not (fcd "web") { fcd "frontend" }
}

def api [] {
    fcd "api"
}
