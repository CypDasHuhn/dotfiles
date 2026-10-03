# seafile

Attaches this machine to the self-hosted Seafile server and syncs the `vault`
library. One module, two OS branches — the mechanisms genuinely differ.

The server, library id and account are fixed in `bootstrap.lua`; this repo
targets one deployment. The only external value is the account password.

## Password

Stored in the gitignored `secrets.lua` at the dotfiles root:

```
secrets.lua
return {
    SEAFILE_PASSWORD = "...",
}
```

`bootstrap.lua` reads it directly with `loadfile` — no shell or nushell
dependency. The nushell profile generator reads the same file and emits each key
as `$env.<KEY>`, so `$env.SEAFILE_PASSWORD` is available in nushell too.

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

The root bootstrap resolves dependencies **before** module bootstraps, so a fresh
machine installs the client and attaches in a single run.
