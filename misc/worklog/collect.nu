#!/usr/bin/env nu

use nextcloud.nu upload-device-work

const script_dir = path self .
const repo_root = path self ../..

def machine-name [] {
    let result = do {
        cd $repo_root
        ^lua -e 'local machine = dofile(".machine.local.lua"); assert(type(machine.name) == "string" and machine.name ~= ""); io.write(machine.name)'
    } | complete

    if $result.exit_code != 0 {
        error make { msg: "Could not read machine name from .machine.local.lua", help: ($result.stderr | str trim) }
    }

    let name = $result.stdout | str trim
    if ($name | is-empty) or ($name =~ '[/\\]') {
        error make { msg: $"Machine name is not safe for a filename: ($name)" }
    }

    $name
}

def git-output [repo: path, args: list<string>] {
    let result = do { ^git -C $repo ...$args } | complete
    if $result.exit_code == 0 {
        $result.stdout | str trim
    } else {
        ""
    }
}

def choose-branch [branches: list<string>, current: string] {
    let candidates = $branches
        | each { str trim }
        | where { not ($in | is-empty) and not ($in | str ends-with "/HEAD") }
        | uniq

    let non_default = $candidates | where {|branch|
        let leaf = $branch | split row "/" | last
        $leaf not-in [main master develop development dev trunk]
    }

    if not ($non_default | is-empty) {
        $non_default | first
    } else if $current in $candidates {
        $current
    } else {
        $candidates | first
    }
}

def infer-branch [repo: path, hash: string] {
    let current = git-output $repo [branch --show-current]
    let local_branches = git-output $repo [for-each-ref "--format=%(refname:short)" refs/heads]
        | lines
        | where { not ($in | is-empty) }

    let reflog_matches = $local_branches | where {|branch|
        git-output $repo [reflog show "--format=%h%x09%gs" $branch]
            | lines
            | any {|entry| $entry | str starts-with $"($hash)\tcommit" }
    }

    if not ($reflog_matches | is-empty) {
        choose-branch $reflog_matches $current
    } else {
        let remotes = git-output $repo [remote] | lines
        let containing = git-output $repo [branch --all --contains $hash "--format=%(refname:short)"]
            | lines
            | where {|branch| not ($branch | is-empty) and $branch not-in $remotes }

        if ($containing | is-empty) {
            "unknown"
        } else {
            choose-branch $containing $current
        }
    }
}

def format-activity [activity: string] {
    if ($activity | is-empty) {
        return "No matching commits found."
    }

    mut repo = ""
    mut commits = []

    for line in ($activity | lines | where { not ($in | is-empty) }) {
        let parsed = $line | parse --regex '^(?<hash>[0-9a-f]+) - (?<subject>.*) \((?<timestamp>[0-9]{4}-[^)]*)\) <(?<author>.*)>\s*$'

        if not ($parsed | is-empty) and not ($repo | is-empty) {
            let commit = $parsed | first
            $commits = $commits | append {
                repo: $repo
                hash: $commit.hash
                subject: $commit.subject
                timestamp: $commit.timestamp
                branch: (infer-branch $repo $commit.hash)
            }
        } else {
            $repo = $line | str trim
        }
    }

    mut markdown = []
    for repo_path in ($commits | get repo | uniq) {
        let repo_commits = $commits | where repo == $repo_path
        $markdown = $markdown | append [
            $"## ($repo_path | path basename)"
            ""
            $"Repository: `($repo_path)`"
            ""
        ]

        for branch in ($repo_commits | get branch | uniq) {
            $markdown = $markdown | append [
                $"### Assumed related branch: `($branch)`"
                ""
            ]

            for commit in ($repo_commits | where branch == $branch) {
                let time = $commit.timestamp | into datetime | format date "%H:%M"
                $markdown = $markdown | append [
                    $"- **($time)** `($commit.hash)` — ($commit.subject)"
                    $"  - Committed: ($commit.timestamp)"
                ]
            }

            $markdown = $markdown | append ""
        }
    }

    $markdown | str join "\n"
}

def main [
    --root: path = $nu.home-dir  # Directory beneath which repositories are discovered.
    --depth: int = 10            # Maximum repository search depth.
    --output: path               # Markdown output path.
    --all-authors                # Include commits from every author.
    --fetch                      # Run `git fetch --all` in each repository first.
    --no-upload                  # Keep the report local instead of uploading it.
] {
    if (which git-standup | is-empty) {
        error make { msg: "git-standup is not installed; run the dotfiles dependency setup first" }
    }

    if not ($root | path exists) {
        error make { msg: $"Scan root does not exist: ($root)" }
    }

    let today = date now | format date "%Y-%m-%d"
    let tomorrow = (date now) + 1day | format date "%Y-%m-%d"
    let machine = machine-name
    let remote_name = $"($today)-($machine)-work.md"
    let output_file = $output | default ($script_dir | path join generated $remote_name)

    mut args = [
        standup
        -m ($depth | into string)
        -F
        -s
        -D iso-strict
        -A $"($today) 00:00:00"
        -B $"($tomorrow) 00:00:00"
    ]

    if $all_authors {
        $args = $args | append [-a all]
    }

    if $fetch {
        $args = $args | append [-f]
    }

    let command_args = $args
    let result = do {
        cd $root
        ^git ...$command_args
    } | complete

    if $result.exit_code != 0 {
        error make { msg: "git-standup failed", help: ($result.stderr | str trim) }
    }

    # git-standup's non-interactive formatter emits a literal `\n` suffix.
    let activity = $result.stdout | str replace --all '\n' '' | str trim
    let activity_text = format-activity $activity

    let document = [
        $"# Git activity for ($today)"
        ""
        $"- Scan root: `($root | path expand)`"
        $"- Search depth: ($depth)"
        "- Branches: best-effort inference from local reflogs, then current containment"
        $"- Generated: (date now | format date '%Y-%m-%dT%H:%M:%S%:z')"
        ""
        $activity_text
        ""
    ] | str join "\n"

    mkdir ($output_file | path dirname)
    $document | save --force $output_file
    print $"Saved commit activity to ($output_file | path expand)"

    if not $no_upload {
        upload-device-work $output_file $remote_name
        print $"Uploaded commit activity to Nextcloud device-work/($remote_name)"
    }
}
