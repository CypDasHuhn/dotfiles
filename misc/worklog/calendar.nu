#!/usr/bin/env nu

use period.nu resolve-period
use nextcloud.nu upload-device-work

const script_dir = path self .
const repo_root = path self ../..
const graph_tenant = "837a9f42-e8ba-4b3c-a0b4-89cd0bfa5b01"

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

def result-details [result: record] {
    [$result.stderr $result.stdout]
        | each { str trim }
        | where { not ($in | is-empty) }
        | str join "\n"
}

def graph-login [] {
    if (which pwsh | is-empty) {
        error make {
            msg: "PowerShell 7 is required for Microsoft Graph calendar access"
            help: "Install PowerShell 7 and Microsoft.Graph.Authentication, then run worklog calendar --login."
        }
    }

    ^pwsh -NoProfile -Command $'Import-Module Microsoft.Graph.Authentication; Connect-MgGraph -TenantId "($graph_tenant)" -Scopes "Calendars.Read" -ContextScope CurrentUser -UseDeviceCode'
}

def local-midnight [date: string, timezone: string] {
    try {
        $date
            | into datetime
            | date to-timezone $timezone
            | format date "%Y-%m-%dT%H:%M:%S%:z"
    } catch {
        error make {
            msg: $"Could not construct a date boundary in timezone ($timezone)"
            help: "Use an IANA timezone such as Europe/Berlin."
        }
    }
}

def calendar-events [start: string, end: string] {
    if (which pwsh | is-empty) {
        error make {
            msg: "PowerShell 7 is required for Microsoft Graph calendar access"
            help: "Install PowerShell 7 and Microsoft.Graph.Authentication, then run worklog calendar --login."
        }
    }

    let graph_script = $script_dir | path join calendar-graph.ps1
    let result = do {
        ^pwsh -NoProfile -File $graph_script -TenantId $graph_tenant -StartDateTime $start -EndDateTime $end
    } | complete

    if $result.exit_code != 0 {
        let details = result-details $result
        let help = if ($details | is-empty) {
            "Run worklog calendar --login once, then retry."
        } else {
            [$details "Run worklog calendar --login once, then retry."] | str join "\n"
        }
        error make {
            msg: "Microsoft Graph calendar request failed"
            help: $help
        }
    }

    let response = try {
        $result.stdout | from json
    } catch {
        error make {
            msg: "Microsoft Graph returned invalid calendar JSON"
            help: "Run worklog calendar --login once, then retry."
        }
    }

    if ("value" in $response) { $response.value } else { [] }
}

def main [
    --output: path
    --no-upload
    --login
    --date: string
    --from: string
    --to: string
    --timezone: string = "Europe/Berlin"
] {
    if $login {
        graph-login
        return
    }

    let period = resolve-period $date $from $to
    let machine = machine-name
    let remote_name = $"($period.slug)-($machine)-calendar.json"
    let output_file = $output | default ($script_dir | path join generated $remote_name)
    let start = local-midnight $period.start_date $timezone
    # Resolve the exclusive date by calendar date, then parse it again. This
    # keeps DST transitions from turning local midnight into 23:00 or 01:00.
    let exclusive_date = $period.end_exclusive | format date "%Y-%m-%d"
    let end = local-midnight $exclusive_date $timezone
    let events = calendar-events $start $end

    let document = {
        source: "calendar"
        device: $machine
        from: $period.start_date
        to: $period.end_date
        timezone: $timezone
        generated: (date now | format date "%Y-%m-%dT%H:%M:%S%:z")
        events: $events
    }

    mkdir ($output_file | path dirname)
    $document | to json --indent 2 | save --force $output_file
    print $"Saved calendar to ($output_file | path expand)"

    if not $no_upload {
        upload-device-work $output_file $remote_name
        print $"Uploaded calendar to Nextcloud device-work/($remote_name)"
    }
}

