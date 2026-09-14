def parse-date [value: string, option: string] {
    if not ($value =~ '^\d{4}-\d{2}-\d{2}$') {
        error make { msg: $"Invalid ($option): ($value). Expected format YYYY-MM-DD." }
    }

    let parsed = try {
        $value | into datetime
    } catch {
        error make { msg: $"Invalid ($option): ($value). Expected format YYYY-MM-DD." }
    }

    if ($parsed | format date "%Y-%m-%d") != $value {
        error make { msg: $"Invalid ($option): ($value). Expected format YYYY-MM-DD." }
    }

    $parsed
}

def dates-between [start: datetime, end: datetime] {
    mut dates = []
    mut current = $start

    while $current <= $end {
        $dates = $dates | append ($current | format date "%Y-%m-%d")
        $current = $current + 1day
    }

    $dates
}

export def resolve-period [
    date?: string
    from_date?: string
    to_date?: string
] {
    let selected_date = $date | default ""
    let selected_from = $from_date | default ""
    let selected_to = $to_date | default ""
    let has_date = not ($selected_date | is-empty)
    let has_from = not ($selected_from | is-empty)
    let has_to = not ($selected_to | is-empty)

    if $has_date and ($has_from or $has_to) {
        error make { msg: "Use either --date or --from/--to, not both." }
    }

    if $has_from != $has_to {
        error make { msg: "Both --from and --to are required for a date range." }
    }

    let start = if $has_from {
        parse-date $selected_from "--from"
    } else if $has_date {
        parse-date $selected_date "--date"
    } else {
        date now | into datetime
    }
    let end = if $has_to {
        parse-date $selected_to "--to"
    } else {
        $start
    }

    if $end < $start {
        error make { msg: $"The end date (($end | format date "%Y-%m-%d")) must not be before the start date (($start | format date "%Y-%m-%d"))." }
    }

    let start_date = $start | format date "%Y-%m-%d"
    let end_date = $end | format date "%Y-%m-%d"
    let is_single_day = $start_date == $end_date
    let display = if $is_single_day {
        $start_date
    } else {
        $"($start_date) to ($end_date)"
    }
    let slug = if $is_single_day {
        $start_date
    } else {
        $"($start_date)-to-($end_date)"
    }

    {
        start_date: $start_date
        end_date: $end_date
        end_exclusive: ($end + 1day)
        display: $display
        slug: $slug
        dates: (dates-between $start $end)
    }
}

export def report-info [name: string] {
    let range = $name | parse --regex '^(?<start>\d{4}-\d{2}-\d{2})-to-(?<end>\d{4}-\d{2}-\d{2})-(?<device>.+)-work\.md$'
    if not ($range | is-empty) {
        let report = $range | first
        return {
            name: $name
            start_date: $report.start
            end_date: $report.end
            device: $report.device
        }
    }

    let daily = $name | parse --regex '^(?<start>\d{4}-\d{2}-\d{2})-(?<device>.+)-work\.md$'
    if ($daily | is-empty) {
        null
    } else {
        let report = $daily | first
        {
            name: $name
            start_date: $report.start
            end_date: $report.start
            device: $report.device
        }
    }
}
