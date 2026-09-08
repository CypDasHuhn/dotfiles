def "nu-complete fcd-directories" [context: string] {
    {
        options: {
            completion_algorithm: substring
            case_sensitive: false
            sort: smart
        }
        completions: (
            ls
            | where type == "dir"
            | each { |entry|
                {
                    value: ($entry.name | path basename)
                    description: $entry.name
                }
            }
        )
    }
}

def --env fcd [
    pattern?: string@"nu-complete fcd-directories"
] {
    let directories = (ls | where type == "dir")
    if $pattern == null {
        return $directories
    }

    let matches = ($directories | where { |entry|
        $entry.name | path basename | str contains --ignore-case $pattern
    })
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
