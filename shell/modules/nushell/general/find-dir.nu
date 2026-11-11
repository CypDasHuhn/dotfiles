const fcd_default_depth = 1
const fcd_excludes = [
    "**/.git/**"
    "**/node_modules/**"
    "**/bin/**"
    "**/obj/**"
    "**/dist/**"
    "**/target/**"
]

def fcd-candidates [depth: int] {
    let cwd = (pwd)
    glob "**/*" --depth $depth --no-file --no-symlink --exclude $fcd_excludes
    | each { |path|
        let relative = ($path | path relative-to $cwd)
        {
            path: $path
            relative: $relative
            name: ($path | path basename)
            depth: ($relative | path split | length)
        }
    }
    | where relative != ""
}

def "nu-complete fcd-directories" [buffer: string, place: record] {
    {
        options: {
            filter: true
            completion_algorithm: substring
            case_sensitive: false
            sort: true
        }
        completions: (
            fcd-candidates $fcd_default_depth
            | each { |entry|
                {
                    value: $entry.relative
                    description: $entry.name
                }
            }
        )
    }
}

def --env fcd [
    pattern?: string@"nu-complete fcd-directories"
    --depth (-d): int = 3
] {
    if $depth < 1 {
        error make { msg: "fcd depth must be at least 1" }
    }

    let directories = (fcd-candidates $depth)
    if $pattern == null {
        return $directories
    }

    let matches = (
        $directories
        | where { |entry|
            let name_match = ($entry.name | str contains --ignore-case $pattern)
            let path_match = ($entry.relative | str contains --ignore-case $pattern)
            ($name_match or $path_match)
        }
        | sort-by depth relative
    )
    if ($matches | is-empty) {
        error make { msg: $"(ansi red)No directory matching '($pattern)' found(ansi reset)"}
    }
    let dir = ($matches | first | get path)
    cd $dir | ignore

    if (($env.IS_NAVIGATION_MODE? | default false) | into bool) {
        ls
    }
}

def --env web [] {
    try {
        fcd "web"
    } catch {
        fcd "frontend"
    }
}

alias api = fcd "api"
