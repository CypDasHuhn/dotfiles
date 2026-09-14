#!/usr/bin/env nu

use period.nu report-info
use nextcloud.nu [delete-device-work list-device-work]

def main [
    --dry-run  # Show what would be removed without deleting it.
] {
    let today = date now | format date "%Y-%m-%d"
    let stale_files = list-device-work | where {|entry|
        if $entry.is_directory {
            false
        } else {
            let report = report-info $entry.name
            if $report == null {
                not ($entry.name | str starts-with $"($today)-")
            } else {
                not (($report.start_date <= $today) and ($report.end_date >= $today))
            }
        }
    }

    if ($stale_files | is-empty) {
        print "No non-today files to remove from Nextcloud device-work."
        return
    }

    for entry in $stale_files {
        if $dry_run {
            print $"Would remove device-work/($entry.name)"
        } else {
            delete-device-work $entry.name
            print $"Removed device-work/($entry.name)"
        }
    }
}
