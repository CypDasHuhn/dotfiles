#!/usr/bin/env nu

use period.nu [report-info resolve-period]
use nextcloud.nu [download-device-work list-device-work]

const script_dir = path self .

def main [
    --prompt: path    # Instructions for the summary.
    --output: path    # Final Codex response path.
    --commits-output: path  # Merged multi-device activity snapshot.
    --date: string    # Summarize commits for this day instead of today (YYYY-MM-DD).
    --from: string
    --to: string
] {
    if (which codex | is-empty) {
        error make { msg: "codex is not installed" }
    }

    let prompt_file = $prompt | default ($script_dir | path join prompt.md)
    if not ($prompt_file | path exists) {
        error make { msg: $"Required prompt file does not exist: ($prompt_file)" }
    }

    let period = resolve-period $date $from $to
    let output_file = $output | default ($script_dir | path join generated $"summary-($period.slug).md")
    let commits_file = $commits_output | default ($script_dir | path join generated $"commits-($period.slug).md")
    let reports = list-device-work
        | where {|entry| not $entry.is_directory and ($entry.name | str ends-with "-work.md") }
        | each {|entry|
            let report = report-info $entry.name
            if $report == null {
                null
            } else {
                $report
            }
        }
        | compact
    let eligible_reports = $reports | where {|report|
        ($report.start_date >= $period.start_date)
        and ($report.end_date <= $period.end_date)
    }
    let activity_files = $eligible_reports | where {|report|
        let covering_reports = $eligible_reports | where {|other|
            ($other.device == $report.device)
            and ($other.name != $report.name)
            and ($other.start_date <= $report.start_date)
            and ($other.end_date >= $report.end_date)
            and (($other.start_date != $report.start_date) or ($other.end_date != $report.end_date))
        }
        $covering_reports | is-empty
    }

    if ($activity_files | is-empty) {
        error make { msg: $"No device worklogs found in Nextcloud for ($period.display)" }
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

    let merged_activity = [
        $"# Combined Git activity for ($period.display)"
        ""
        ($activities | str join "\n")
    ] | str join "\n"

    mkdir ($commits_file | path dirname)
    $merged_activity | save --force $commits_file
    print $"Saved merged Git activity to ($commits_file | path expand)"

    let request = [
        (open --raw $prompt_file | str trim)
        ""
        $"The work period is ($period.display). The final Markdown heading must be # Work for ($period.display). For a multi-day period, group entries by date and keep each date visible."
        ""
        $"Use only the following collected Git activity from all devices for ($period.display) as source data:"
        ""
        $merged_activity
        ""
        "Return only the final Markdown summary."
    ] | str join "\n"

    mkdir ($output_file | path dirname)
    $request | ^codex exec --ephemeral --sandbox read-only --skip-git-repo-check --output-last-message $output_file -

    if $env.LAST_EXIT_CODE != 0 {
        error make { msg: $"Codex failed with exit code ($env.LAST_EXIT_CODE)" }
    }

    let expected_heading = $"# Work for ($period.display)"
    let summary = open --raw $output_file | str trim
    if not ($summary | str starts-with $expected_heading) {
        [$expected_heading "" $summary] | str join "\n" | save --force $output_file
    }

    print $"Saved AI summary to ($output_file | path expand)"
}
