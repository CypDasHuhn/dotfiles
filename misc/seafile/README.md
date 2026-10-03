# seafile

Attaches this machine to the self-hosted Seafile server and syncs the `vault`
library. One module, two OS branches — the mechanisms genuinely differ.

The server, library id and account are fixed in `bootstrap.lua`; this repo
targets one deployment. The only external value is the account password.

## Password

Stored in the gitignored nushell secrets file, as key `SEAFILE_PASSWORD`:

```
shell/modules/nushell/secrets.nu
{
    SEAFILE_PASSWORD: "..."
}
```

That is the same file the shell loads via `load-env`, so `$env.SEAFILE_PASSWORD`
is available in nushell. `bootstrap.lua` reads it with
`nu -c 'open --raw ... | from nuon | get SEAFILE_PASSWORD'` on both platforms.

The password is only needed for the initial attach; afterwards the client stores
its own token.

## Unix branch

Drives the headless `seaf-cli` (from the `seafile` AUR package):

1. `seaf-cli init` if the client data dir is missing.
2. Start `seaf-daemon` if it is not running.
3. Download the library to the resolved `vault` path if not already attached.
4. Enable `seaf-cli@$USER.service` so syncing resumes on boot. It is a **system**
   unit, so no `loginctl enable-linger` is needed.

## Windows branch

Uses the GUI sync client (`Seafile.Seafile`), preconfigured via
`%USERPROFILE%\seafile.ini` (`preconfigure.ps1` obtains an API token from
`/api2/auth-token/` and writes the file). This skips the login wizard.

**Caveat:** Seafile exposes no preconfigure key for *which* library to sync, so
selecting `cyps-vault` in the client after launch is a manual GUI step.

> The Windows branch has not been run on a Windows machine yet (built on Linux).
> Treat it as a first cut and iterate on the actual box.

## Ordering

The module bootstrap runs before dependency resolution, so on a fresh machine it
skips with "not installed yet". Run `deps` (or the full bootstrap again) to
install the client, then the module attaches.
