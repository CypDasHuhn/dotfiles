#!/usr/bin/env nu

use period.nu resolve-period
use nextcloud.nu [download-device-work list-device-work]

const script_dir = path self .
const context_file = path self context.md

def make-resource [name: string, start: string, end: string] {
    let resource_period = try {
        resolve-period "" $start $end
    } catch {
        null
    }

    if $resource_period == null {
        null
    } else {
        {
            name: $name
            start_date: $resource_period.start_date
            end_date: $resource_period.end_date
        }
    }
}

def resource-info [entry: record] {
    if $entry.is_directory {
        return null
    }

    let json_matches = $entry.name
        | parse --regex '(?<start>\d{4}-\d{2}-\d{2}):(?<end>\d{4}-\d{2}-\d{2})\.json$'
    if not ($json_matches | is-empty) {
        let matched = $json_matches | first
        return (make-resource $entry.name $matched.start $matched.end)
    }

    let range_matches = $entry.name
        | parse --regex '(?<start>\d{4}-\d{2}-\d{2})-to-(?<end>\d{4}-\d{2}-\d{2})-.+-work\.md$'
    if not ($range_matches | is-empty) {
        let matched = $range_matches | first
        return (make-resource $entry.name $matched.start $matched.end)
    }

    let daily_matches = $entry.name
        | parse --regex '(?<start>\d{4}-\d{2}-\d{2})-.+-work\.md$'
    if not ($daily_matches | is-empty) {
        let matched = $daily_matches | first
        return (make-resource $entry.name $matched.start $matched.start)
    }

    null
}

def main [
    --prompt: path
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
    let staging_dir = $script_dir | path join .tmp
    if ($staging_dir | path exists) {
        rm --recursive --force $staging_dir
    }
    mkdir $staging_dir
    if not ($context_file | path exists) {
        error make { msg: $"Required context file does not exist: ($context_file | path expand)" }
    }
    open --raw $context_file | save --force ($staging_dir | path join context.md)

    let resources = list-device-work
        | each {|entry| resource-info $entry }
        | compact
        | where {|resource|
            (($resource.start_date >= $period.start_date)
            and ($resource.end_date <= $period.end_date))
        }

    if ($resources | is-empty) {
        error make {
            msg: $"No resources found in Nextcloud for ($period.display)"
            help: "Expected JSON or Markdown resources whose filename date range is contained in the requested period."
        }
    }

    for resource in $resources {
        let destination = $staging_dir | path join $resource.name
        download-device-work $resource.name | save --force $destination
        print $"Downloaded device-work/($resource.name)"
    }

    print ""
    print "Fetched sources:"
    for resource in $resources {
        print $"  ($resource.name)"
    }
    let acceptance = input "Invoke Codex with these sources? [y/N] "
    if ($acceptance | str trim | str downcase) not-in ["y" "yes"] {
        print "Cancelled."
        return
    }

    let request = [
        (open --raw $prompt_file | str trim)
        ""
        $"The work period is ($period.display). The final Markdown heading must be # Work for ($period.display)."
        "Read context.md and every JSON or Markdown resource file in the current working directory and use all of them as source data."
        "Return only the final Markdown summary."
    ] | str join "\n"

    cd $staging_dir
    ^codex --sandbox read-only $request
}
