# nextcloud

Syncs the `vault` folder with the self-hosted Nextcloud server at
`https://nextcloud.cypdashuhn.de` as user `cyp`.

`dependencies.lua` handles installs (`nextcloud-client` on Unix,
`Nextcloud.NextcloudDesktop` via winget on Windows); `bootstrap.lua`
orchestrates the setup per OS and decommissions an existing Seafile client.

## Password

The app password is stored in the gitignored `secrets.lua` at the dotfiles root:

```
secrets.lua
return {
    NEXTCLOUD_APP_PASSWORD = "...",
}
```

Use an app password, not the account password. Generate one in the web UI
(personal settings → Security → Devices & sessions → *Create new app password*)
or server-side (`occ user:auth-tokens:add <user> --name=<device> -n`).

## Branches

The client that consumes Nextcloud **Client Push** (`notify_push`, i.e.
real-time sync) is the official desktop client — so it is used wherever a
display + keyring exist:

- **Windows** → desktop client. Installs a Startup-folder launcher running
  `nextcloud --background`.
- **Linux desktop** (`$DISPLAY`/`$WAYLAND_DISPLAY` set) → desktop client.
  Installs `~/.config/autostart/nextcloud.desktop` (XWayland, `--background`)
  and removes any leftover headless `nextcloudcmd` units.
- **Linux headless** → `nextcloudcmd` driven by a systemd service + 3-min timer.
  The desktop client needs a keyring/display, so headless uses the CLI instead
  (poll-based, no push).

The module does **not** pre-write the account config — seeding an account without
credentials just makes the client prompt forever. Instead you add the account in
the client **once** (log in with the app password, set the sync folder to
`vault`); it then writes the config and stores credentials in the keyring. The
module only sets up autostart and removes the headless units so exactly one
engine owns `~/vault`.

The tray/window is background-only: hide the tray icon via the OS (Windows:
Taskbar settings → *Other system tray icons*; KDE: System Tray → Entries →
Hidden). Headless has no UI at all.

## Seafile migration

If `seaf-cli`/`seaf-daemon` or `~/.ccnet` is present, the module disables
`seaf-cli@<user>`, removes the `seafile` package (pacman) and deletes
`~/.ccnet` / `~/.local/share/seafile` before configuring Nextcloud, so the two
clients never fight over `~/vault`. Idempotent.

## Ordering

The root bootstrap resolves dependencies **before** module bootstraps, so a
fresh machine installs the client and configures sync in a single run.

> One syncer per folder: never run `nextcloudcmd` and the desktop client over the
> same folder/account — they fork conflicted copies. The desktop branch removes
> the `nextcloudcmd` units automatically; going the other way is manual.
