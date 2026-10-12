#!/usr/bin/env nu

use period.nu resolve-period
use nextcloud.nu upload-device-work

const script_dir = path self .
const repo_root = path self ../..
const graph_origin = "https://graph.microsoft.com/v1.0"

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

def graph-token [] {
    if (which az | is-empty) {
        error make {
            msg: "Azure CLI (az) is required for Microsoft Graph calendar access"
            help: "Run az login first, then retry. No separate Graph secret is used by this script."
        }
    }

    let result = do {
        ^az account get-access-token --resource https://graph.microsoft.com --output json
    } | complete

    if $result.exit_code != 0 {
        error make {
            msg: "Could not obtain a Microsoft Graph access token"
            help: (result-details $result)
        }
    }

    let token_response = try {
        $result.stdout | from json
    } catch {
        error make { msg: "Azure CLI returned invalid token JSON" }
    }
    let token = $token_response.accessToken? | default ""

    if ($token | is-empty) {
        error make { msg: "Azure CLI did not return an access token" }
    }

    $token
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

def calendar-url [start: string, end: string] {
    let encoded_start = $start | url encode
    let encoded_end = $end | url encode
    $"($graph_origin)/me/calendar/calendarView?startDateTime=($encoded_start)&endDateTime=($encoded_end)&%24top=1000"
}

def graph-page [token: string, url: string] {
    try {
        http get --raw --max-time 120sec --headers {
            Authorization: $"Bearer ($token)"
            Accept: "application/json"
        } $url | from json
    } catch {
        error make {
            msg: "Microsoft Graph calendar request failed"
            help: "Check az login, the account's calendar permission, and the selected date range."
        }
    }
}

def calendar-events [token: string, start: string, end: string] {
    mut next_url = (calendar-url $start $end)
    mut events = []

    while $next_url != null {
        let page = graph-page $token $next_url
        let page_events = if ("value" in $page) { $page.value } else { [] }
        $events = $events | append $page_events
        $next_url = if ("@odata.nextLink" in $page) {
            $page | get "@odata.nextLink"
        } else {
            null
        }
    }

    $events
}

def main [
    --output: path
    --no-upload
    --date: string
    --from: string
    --to: string
    --timezone: string = "Europe/Berlin"
] {
    let period = resolve-period $date $from $to
    let machine = machine-name
    let remote_name = $"($period.slug)-($machine)-calendar.json"
    let output_file = $output | default ($script_dir | path join generated $remote_name)
    let start = local-midnight $period.start_date $timezone
    # Resolve the exclusive date by calendar date, then parse it again. This
    # keeps DST transitions from turning local midnight into 23:00 or 01:00.
    let exclusive_date = $period.end_exclusive | format date "%Y-%m-%d"
    let end = local-midnight $exclusive_date $timezone
    let token = graph-token
    let events = calendar-events $token $start $end

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

