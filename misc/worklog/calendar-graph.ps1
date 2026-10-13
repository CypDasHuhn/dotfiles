param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$StartDateTime,

    [Parameter(Mandatory = $true)]
    [string]$EndDateTime
)

$ErrorActionPreference = "Stop"

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    # Connect-MgGraph reuses the current user's cached delegated login when
    # one exists. Use calendar.nu --login for the one-time device login.
    $null = Connect-MgGraph `
        -TenantId $TenantId `
        -Scopes "Calendars.Read" `
        -ContextScope CurrentUser `
        -ErrorAction Stop

    $nextUri = "https://graph.microsoft.com/v1.0/me/calendarView" +
        "?startDateTime=$([uri]::EscapeDataString($StartDateTime))" +
        "&endDateTime=$([uri]::EscapeDataString($EndDateTime))" +
        "&%24top=1000"
    $events = [System.Collections.Generic.List[object]]::new()

    while ($null -ne $nextUri -and $nextUri -ne "") {
        $page = Invoke-MgGraphRequest `
            -Method GET `
            -Uri $nextUri `
            -OutputType PSObject `
            -ErrorAction Stop

        foreach ($event in @($page.value)) {
            [void]$events.Add($event)
        }

        $nextUri = $page.'@odata.nextLink'
    }

    [pscustomobject]@{
        value = $events.ToArray()
    } | ConvertTo-Json -Depth 100 -Compress
}
catch {
    [Console]::Error.WriteLine(($_ | Out-String).Trim())
    exit 1
}
