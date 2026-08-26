# Daily Git worklog

This workflow uses [git-standup](https://github.com/nilbuild/git-standup) for recursive repository discovery and same-day commit collection. Each device uploads its report to the authenticated user's `device-work` directory on `https://nextcloud.i2solutions.de`. The summarizer downloads all reports for the current date and sends them with a separate prompt to Codex.

Nextcloud credentials come from the Nushell environment:

```nu
{
    I2_NEXT_CLOUD_USER: "..."
    I2_NEXT_CLOUD_PASSWORD: "..."
}
```

Install dependencies through the normal dotfiles bootstrap, or install the collector directly:

```sh
npm install -g --prefix "$HOME/.local" git-standup
```

Collect today's commits beneath the home directory and upload them:

```sh
nu misc/worklog/collect.nu
```

The machine name is read from `.machine.local.lua`. The uploaded filename is `YYYY-MM-DD-machine-name-work.md`; collecting again on the same device and date replaces that device's previous report.

After all devices have uploaded, generate one combined summary:

```sh
nu misc/worklog/summarize.nu
```

After regenerating the shell profile, the same scripts are available directly in Nushell:

```nu
worklog collect
worklog summarize
worklog cleanup --dry-run
worklog cleanup
```

Local outputs are written beneath `misc/worklog/generated/`. During summarization, every current-date device report is merged into `commits.md`; this is the exact activity snapshot supplied to Codex. The final response is written to `summary.md`. The repository's existing `generated/` ignore rule keeps them out of Git.

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
```

Manually remove every non-today file from the personal `device-work` directory:

```sh
nu misc/worklog/cleanup.nu --dry-run
nu misc/worklog/cleanup.nu
```

Child directories are never deleted.

`git-standup` searches all branches by default. Git commits do not record the branch on which they were originally created, so branch grouping is explicitly best-effort: the collector first checks local branch reflogs and then falls back to branches that currently contain the commit. Deleted branches, rebases, and expired reflogs can make the result incorrect or `unknown`.
