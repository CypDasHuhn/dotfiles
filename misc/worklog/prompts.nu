#!/usr/bin/env nu

use period.nu resolve-period
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

def default-history [] {
    $nu.home-dir | path join dotfiles ai generated prompt-history.json
}

export def main [
    --from: string
    --to: string
    --history-file: path
    --output: path
    --no-upload
] {
    let machine = machine-name
    let period = resolve-period "" $from $to
    let remote_name = $"prompt-history-($machine)-($period.start_date):($period.end_date).json"
    let history_file = $history_file | default (default-history)

    if not ($history_file | path exists) {
        error make {
            msg: $"Prompt history file does not exist: ($history_file | path expand)"
            help: "The Codex/Copilot hooks write it to ~/dotfiles/ai/generated/prompt-history.json."
        }
    }

    let history = try {
        open --raw $history_file | from json
    } catch {
        error make { msg: $"Could not parse prompt history JSON: ($history_file | path expand)" }
    }

    let prompts = $history | where {|entry|
        let message_date = $entry.message_datetime | into datetime | format date "%Y-%m-%d"
        $message_date >= $period.start_date and $message_date <= $period.end_date
    }

    let document = {
        source: "prompt-history"
        machine: $machine
        from: $period.start_date
        to: $period.end_date
        generated: (date now | format date "%Y-%m-%dT%H:%M:%S%:z")
        prompts: $prompts
    }

    let local_name = $remote_name | str replace ":" "_"
    let output_file = $output | default (
        $script_dir | path join generated $local_name
    )
    mkdir ($output_file | path dirname)
    $document | to json --indent 2 | save --force $output_file

    print $"Saved ($prompts | length) prompt-history entries to ($output_file | path expand)"

    if not $no_upload {
        upload-device-work $output_file $remote_name
        print $"Uploaded prompt history to Nextcloud device-work/($remote_name)"
    }
}
