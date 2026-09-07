#!/usr/bin/env nu

const queue_filename = "TODO-QUEUE.md"
const state_version = 1

def repository-root [] {
    let result = do { ^git rev-parse --show-toplevel } | complete
    if $result.exit_code != 0 {
        error make {
            msg: "ai queue await must run inside a Git repository"
            help: ($result.stderr | str trim)
        }
    }

    $result.stdout | str trim | path expand
}

def queue-path [root: path] {
    $root | path join $queue_filename
}

def state-path [root: path] {
    let configured_state_home = ($env.XDG_STATE_HOME? | default "")
    let state_home = if ($configured_state_home | is-empty) {
        $nu.home-dir | path join ".local" "state"
    } else {
        $configured_state_home
    }

    let repository_key = $root | hash sha256
    $state_home | path join "dotfiles" "ai-queue" $"($repository_key).json"
}

def parse-queue [queue: path] {
    mut entries = []

    for row in (open --raw $queue | lines | enumerate) {
        if $row.item =~ '^\s*-\s+\[' {
            let matches = $row.item
                | parse --regex '^\s*-\s+\[(?<status>[ xX])\]\s+(?<id>[A-Za-z0-9][A-Za-z0-9._-]*)\s*:\s*(?<title>.*?)\s*$'

            if ($matches | is-empty) {
                error make {
                    msg: $"Invalid queue entry on line ($row.index + 1)"
                    help: "Use '- [ ] ID: title' or '- [x] ID: title'; IDs contain only letters, digits, '.', '_' and '-'."
                }
            }

            let match = $matches | first
            let title = $match.title | str trim
            if ($title | is-empty) {
                error make { msg: $"Queue entry ($match.id) on line ($row.index + 1) has an empty title" }
            }

            $entries = $entries | append {
                id: $match.id
                title: $title
                pending: ($match.status == " ")
                line: ($row.index + 1)
            }
        }
    }

    for entry in $entries {
        if (($entries | where id == $entry.id | length) > 1) {
            error make { msg: $"Queue item ID appears more than once: ($entry.id)" }
        }
    }

    $entries
        | where pending
        | each {|entry|
            let fingerprint = { id: $entry.id, title: $entry.title } | to json | hash sha256
            { id: $entry.id, title: $entry.title, fingerprint: $fingerprint }
        }
}

def load-state [state: path, root: path] {
    if not ($state | path exists) {
        return []
    }

    let data = try {
        open --raw $state | from json
    } catch {
        error make { msg: $"Could not read AI queue state: ($state)" }
    }

    if ($data.version? | default 0) != $state_version {
        error make { msg: $"Unsupported AI queue state version in ($state)" }
    }
    if ($data.repository? | default "") != $root {
        error make { msg: $"AI queue state belongs to a different repository: ($state)" }
    }

    $data.pending? | default []
}

def save-state [state: path, root: path, pending: list] {
    mkdir ($state | path dirname)
    {
        version: $state_version
        repository: $root
        pending: $pending
    } | to json | save --force $state
}

def pending-changes [previous: list, current: list] {
    mut changes = []

    for item in $current {
        let matches = $previous | where id == $item.id
        if ($matches | is-empty) {
            $changes = $changes | append { change: "new", id: $item.id, title: $item.title }
        } else if (($matches | first).fingerprint != $item.fingerprint) {
            $changes = $changes | append { change: "changed", id: $item.id, title: $item.title }
        }
    }

    $changes
}

def check-queue [root: path] {
    let queue = queue-path $root
    if not ($queue | path exists) {
        error make { msg: $"Queue file no longer exists: ($queue)" }
    }

    let state = state-path $root
    let previous = load-state $state $root
    let current = parse-queue $queue
    let changes = pending-changes $previous $current
    save-state $state $root $current

    if not ($changes | is-empty) {
        {
            event: "ai.queue.pending_changed"
            repository: $root
            queue_file: $queue
            detected_at: (date now | format date "%Y-%m-%dT%H:%M:%S%:z")
            items: $changes
            next_action: {
                command: "ai queue await"
                reason: "Re-arm the queue listener before processing these items."
            }
        } | to json --raw
    }
}

export def await-queue [] {
    let root = repository-root

    if (which watchexec | is-empty) {
        error make {
            msg: "watchexec is not installed"
            help: "Run the dotfiles dependency bootstrap, then retry."
        }
    }

    let queue = queue-path $root
    if not ($queue | path exists) {
        error make {
            msg: $"Queue file does not exist: ($queue)"
            help: "Create TODO-QUEUE.md using the format documented in ai/queue/README.md before awaiting it."
        }
    }

    let state = state-path $root
    let current = parse-queue $queue
    save-state $state $root $current

    let watcher_args = [
        "--watch" $queue
        "--no-vcs-ignore"
        "--debounce" "750ms"
        # Without --postpone, Watchexec emits its startup event after installing
        # the watch, reconciling changes made between the baseline and startup.
        "--only-emit-events"
        "--quiet"
    ]

    ^watchexec ...$watcher_args
        | lines
        | where {|line| not ($line | str trim | is-empty) }
        | each { check-queue $root }
        | where {|event| not ($event | is-empty) }
        | first
}
