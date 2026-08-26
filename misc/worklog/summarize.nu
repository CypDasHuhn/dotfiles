#!/usr/bin/env nu

use nextcloud.nu [download-device-work list-device-work]

const script_dir = path self .

def main [
    --prompt: path    # Instructions for the summary.
    --output: path    # Final Codex response path.
] {
    if (which codex | is-empty) {
        error make { msg: "codex is not installed" }
    }

    let prompt_file = $prompt | default ($script_dir | path join prompt.md)
    let output_file = $output | default ($script_dir | path join generated summary.md)

    if not ($prompt_file | path exists) {
        error make { msg: $"Required prompt file does not exist: ($prompt_file)" }
    }

    let today = date now | format date "%Y-%m-%d"
    let activity_files = list-device-work | where {|entry|
        (not $entry.is_directory) and ($entry.name | str starts-with $"($today)-") and ($entry.name | str ends-with "-work.md")
    }

    if ($activity_files | is-empty) {
        error make { msg: $"No device worklogs found in Nextcloud for ($today)" }
    }

    mut activities = []
    for entry in $activity_files {
        $activities = $activities | append [
            $"## Device worklog: ($entry.name)"
            ""
            (download-device-work $entry.name | str trim)
            ""
        ]
    }

    let request = [
        (open --raw $prompt_file | str trim)
        ""
        $"Use only the following collected Git activity from all devices for ($today) as source data:"
        ""
        ($activities | str join "\n")
        ""
        "Return only the final Markdown summary."
    ] | str join "\n"

    mkdir ($output_file | path dirname)
    $request | ^codex exec --ephemeral --sandbox read-only --skip-git-repo-check --output-last-message $output_file -

    if $env.LAST_EXIT_CODE != 0 {
        error make { msg: $"Codex failed with exit code ($env.LAST_EXIT_CODE)" }
    }

    print $"Saved AI summary to ($output_file | path expand)"
}
