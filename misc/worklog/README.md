# Git worklog

The summary command consumes work resources from the authenticated user's
`device-work` directory on `https://nextcloud.i2solutions.de`. Resource
filenames use a source-specific prefix and end in `YYYY-MM-DD:YYYY-MM-DD.json`.
It downloads every resource for the requested period and starts Codex with the
shared prompt from a clean local staging directory. The existing Git collector
remains documented below while source-specific collectors are migrated to the
resource format.

Nextcloud credentials come from the Nushell environment:

```nu
{
    I2_NEXT_CLOUD_USER: "..."
    I2_NEXT_CLOUD_PASSWORD: "..."
}
```

Install dependencies through the normal dotfiles bootstrap, or install the
collector directly:

```sh
npm install -g --prefix "$HOME/.local" git-standup
```

Collect today's commits beneath the home directory and upload them:

```sh
nu misc/worklog/collect.nu
```

Run the MS Teams extractor for an inclusive date range and upload it:

```sh
nu misc/worklog/teams.nu msteams-2026-10-01:2026-10-12
```

Upload the Codex and Copilot prompt history for an inclusive date range:

```sh
nu misc/worklog/prompts.nu --from 2026-10-01 --to 2026-10-12
```

The hooks for both tools append to
`~/dotfiles/ai/generated/prompt-history.json`. The prompt uploader filters that
shared history by `message_datetime`, writes a JSON bundle, and uploads it to
`device-work` in Nextcloud as
`prompt-history-<machine>-YYYY-MM-DD:YYYY-MM-DD.json`. The machine segment is
read from `.machine.local.lua`, so histories from different machines cannot
overwrite one another. Use `--history-file PATH` to override the hook output
or `--no-upload` to generate the local JSON only.

Export the Microsoft Graph calendar for an inclusive date range and upload it:

```sh
nu misc/worklog/calendar.nu --from 2026-10-01 --to 2026-10-12
```

Calendar access reuses the current Azure CLI login; no additional Microsoft
Graph secret keys are needed. Install Azure CLI and run `az login` with an
account that has delegated `Calendars.Read` consent. The existing
`I2_NEXT_CLOUD_USER` and `I2_NEXT_CLOUD_PASSWORD` secrets are still used for the
upload.

The machine name is read from `.machine.local.lua`. A single-day upload uses
`YYYY-MM-DD-machine-name-work.md`, while a range upload uses
`YYYY-MM-DD-to-YYYY-MM-DD-machine-name-work.md`. Collecting again on the same
device and period replaces that device's previous report.

After all sources have uploaded, generate one combined summary:

```sh
nu misc/worklog/summarize.nu
```

To summarize an inclusive range:

```sh
nu misc/worklog/summarize.nu --from 2026-08-17 --to 2026-08-21
```

After regenerating the shell profile, the same scripts are available directly in
Nushell:

```nu
worklog collect
worklog teams msteams-2026-10-01:2026-10-12
worklog prompts --from 2026-10-01 --to 2026-10-12
worklog calendar --from 2026-10-01 --to 2026-10-12
worklog summarize
worklog cleanup --dry-run
worklog cleanup
```

`worklog teams` runs the extractor in
`~/source/repos/msteams-history-extractor`, includes both dates in the range,
combines its calls and messages into one JSON document, and uploads it to
`device-work` in Nextcloud. Its required target format is exactly
`[name]-[YYYY-MM-DD]:[YYYY-MM-DD]`; for example, the remote object for the
command above is `msteams-2026-10-01:2026-10-12`. Use `--no-upload` to generate
the local JSON only, or `--extractor PATH` / `--leveldb PATH` to override the
extractor inputs.

`worklog calendar` calls Microsoft Graph `calendarView` for the selected period,
follows paginated results, writes the range and returned events to JSON, and
uploads `YYYY-MM-DD[-to-YYYY-MM-DD]-machine-calendar.json` to `device-work`. Use
`--no-upload` to generate the local JSON only or `--timezone ZONE` to change the
date-boundary timezone.

Local outputs are written beneath `misc/worklog/generated/`. During
summarization, every device report within the requested period is merged into a
date-labeled `commits-*.md`; this is the exact activity snapshot supplied to
Codex. The final response is written to a matching date-labeled `summary-*.md`.
The repository's existing `generated/` ignore rule keeps them out of Git. Local
outputs are written beneath `misc/worklog/generated/`. During summarization,
`misc/worklog/.tmp/` is removed and recreated, then every Nextcloud resource
ending in the requested `YYYY-MM-DD:YYYY-MM-DD.json` range is downloaded into
it. Codex runs from that directory so it can inspect all resources, and its
final response is written to a matching date-labeled `summary-*.md`. Both
locations are ignored by Git.

Useful collector options:

```sh
# Scan a different root or deeper directory tree
nu misc/worklog/collect.nu --root ~/repos --depth 6

# Include every author instead of each repository's configured Git user
nu misc/worklog/collect.nu --all-authors

# Fetch remotes before collecting local history
nu misc/worklog/collect.nu --fetch

# Collect locally without uploading
nu misc/worklog/collect.nu --no-upload

# Collect a specific day's commits instead of today's
nu misc/worklog/collect.nu --date 2026-08-20

nu misc/worklog/collect.nu --from 2026-08-17 --to 2026-08-21
```

`summarize.nu` accepts `--date YYYY-MM-DD` or an inclusive
`--from YYYY-MM-DD --to YYYY-MM-DD` range. The default local files include the
selected date or range in their names.

Manually remove every worklog that does not include today from the personal
`device-work` directory:

```sh
nu misc/worklog/cleanup.nu --dry-run
nu misc/worklog/cleanup.nu
```

Child directories are never deleted.

`git-standup` searches all branches by default. Git commits do not record the
branch on which they were originally created, so branch grouping is explicitly
best-effort: the collector first checks local branch reflogs and then falls back
to branches that currently contain the commit. Deleted branches, rebases, and
expired reflogs can make the result incorrect or `unknown`.
