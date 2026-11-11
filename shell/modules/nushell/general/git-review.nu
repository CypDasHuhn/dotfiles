def "nu-complete git-review groups" [] {
    let result = (do -i { ^git-review group list --json } | complete)
    if $result.exit_code != 0 {
        return []
    }

    try {
        $result.stdout
        | from json
        | each { |group| { value: $group.name } }
    } catch {
        []
    }
}

def "nu-complete git-review commits" [] {
    let result = (do -i { ^git log --format="%H%x09%h%x09%s" } | complete)
    if $result.exit_code != 0 {
        return []
    }

    try {
        $result.stdout
        | lines
        | each { |line|
            let fields = ($line | split row "\t")
            {
                value: ($fields | get 1)
                description: ($fields | skip 2 | str join "\t")
                extra: [($fields | get 0)]
            }
        }
    } catch {
        []
    }
}

export extern "git-review status" [
    --json
    --no-init
]

export extern "git-review fragment inspect" [
    --commit: string@"nu-complete git-review commits"
    --path: path
    --json
]

export extern "git-review fragment list" [
    --json
    --unassigned
    --summary
    --group: string@"nu-complete git-review groups"
]

export extern "git-review group add" [
    --name: string@"nu-complete git-review groups"
    --commit: string@"nu-complete git-review commits"
    --path: path
]

export extern "git-review group assign" [
    --name: string@"nu-complete git-review groups"
    --commit: string@"nu-complete git-review commits"
    --path: path
    --path-glob: string
    --old-start: int
    --old-lines: int
    --new-start: int
    --new-lines: int
    --reassign
    --dry-run
    --json
]

export extern "git-review group view" [
    --name: string@"nu-complete git-review groups"
]

export extern "git-review group project" [
    --name: string@"nu-complete git-review groups"
]

export extern "git-review group accept" [
    --name: string@"nu-complete git-review groups"
    --path: path
]

export extern "git-review group list" [
    --json
    --summary
]
