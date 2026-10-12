#!/usr/bin/env nu

use period.nu resolve-period
use nextcloud.nu [download-device-work list-device-work]

const script_dir = path self .

def main [
    --prompt: path
    --output: path
    --date: string
    --from: string
    --to: string
] {
    if (which codex | is-empty) {
        error make { msg: "codex is not installed" }
    }

    let prompt_file = $prompt
        | default ($script_dir | path join prompt.md)
        | path expand
    if not ($prompt_file | path exists) {
        error make { msg: $"Required prompt file does not exist: ($prompt_file)" }
    }

    let period = resolve-period $date $from $to
    let resource_suffix = $"($period.start_date):($period.end_date).json"
    let staging_dir = $script_dir | path join .tmp
    if ($staging_dir | path exists) {
        rm --recursive --force $staging_dir
    }
    mkdir $staging_dir

    let resources = list-device-work
        | where {|entry|
            not $entry.is_directory
            and ($entry.name | str ends-with $resource_suffix)
        }

    if ($resources | is-empty) {
        error make {
            msg: $"No resources found in Nextcloud for ($period.display)"
            help: $"Expected filenames ending in ($resource_suffix)"
        }
    }

    for resource in $resources {
        let destination = $staging_dir | path join $resource.name
        download-device-work $resource.name | save --force $destination
        print $"Downloaded device-work/($resource.name)"
    }

    let output_file = $output
        | default ($script_dir | path join generated $"summary-($period.slug).md")
        | path expand
    mkdir ($output_file | path dirname)

    let request = [
        (open --raw $prompt_file | str trim)
        ""
        $"The work period is ($period.display). The final Markdown heading must be # Work for ($period.display)."
        "Read every JSON resource file in the current working directory and use all of them as source data."
        "Return only the final Markdown summary."
    ] | str join "\n"

    let result = do {
        cd $staging_dir
        $request | ^codex exec --ephemeral --sandbox read-only --skip-git-repo-check --output-last-message $output_file -
    } | complete

    if $result.exit_code != 0 {
        error make { msg: $"Codex failed with exit code ($result.exit_code)", help: ($result.stderr | str trim) }
    }

    print $"Saved AI summary to ($output_file)"
}
