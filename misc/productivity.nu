#!/usr/bin/env nu

def round2 [value: float] {
    $value | math round --precision 2
}

def main [
    --weekly-hours: float = 35.0
    --monthly-meeting-hours: float = 5.0
    --yearly-vacation-days: float = 24.0 
    --yearly-sick-days: float = 3.0
] {
    let goal = 85.0
    let weeks_per_month = 4.333333
    let workdays_per_week = 5.0
    let monthly_vacation_days = $yearly_vacation_days / 12
    let monthly_sick_days = $yearly_sick_days / 12

    #region validation 
    if $weekly_hours <= 0 or $weeks_per_month <= 0 or $workdays_per_week <= 0 {
        error make { msg: "Weekly hours, weeks per month, and workdays per week must be greater than zero." }
    }

    if $monthly_meeting_hours < 0 or $monthly_vacation_days < 0 or $monthly_sick_days < 0 {
        error make { msg: "Meeting hours, vacation days, and sick days cannot be negative." }
    }

    if $goal < 0 or $goal > 100 {
        error make { msg: "The goal must be between 0 and 100 percent." }
    }
    #endregion

    let hours_per_workday = $weekly_hours / $workdays_per_week
    let vacation_hours = $monthly_vacation_days * $hours_per_workday
    let sick_hours = $monthly_sick_days * $hours_per_workday
    let total_unproductive_hours = $monthly_meeting_hours + $vacation_hours + $sick_hours

    let monthly_potential_hours = $weekly_hours * $weeks_per_month
    let monthly_billable_hours = $monthly_potential_hours - $total_unproductive_hours

    if $monthly_billable_hours < 0 {
        error make { msg: "The monthly unproductive hours exceed the monthly potential hours." }
    }

    let top_achievable_percent = $monthly_billable_hours / $monthly_potential_hours * 100
    let goal_margin = $top_achievable_percent - $goal

    #region output
    let breakdown = [
        { metric: "Monthly potential hours", value: (round2 $monthly_potential_hours) }
        { metric: "Vacation hours", value: (round2 $vacation_hours) }
        { metric: "Sick hours", value: (round2 $sick_hours) }
        { metric: "Maintenance meeting hours", value: (round2 $monthly_meeting_hours) }
        { metric: "Total unproductive hours", value: (round2 $total_unproductive_hours) }
        { metric: "Monthly billable hours", value: (round2 $monthly_billable_hours) }
    ]

    print ($breakdown | table)

    print $"Top achievable productivity: (round2 $top_achievable_percent)%"
    print $"Margin above goal: (round2 $goal_margin) percentage points"
    #endregion
}
