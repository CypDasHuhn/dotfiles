# nextcloud

Syncs the `vault` folder with the self-hosted Nextcloud server at
`https://nextcloud.cypdashuhn.de` as user `cyp`. One module, two OS branches —
the mechanisms genuinely differ.

The server URL, account and target var are fixed in `bootstrap.lua`; this repo
targets one deployment. The only external value is an **app password**.

## Password

Stored in the gitignored `secrets.lua` at the dotfiles root:

```
secrets.lua
return {
    NEXTCLOUD_APP_PASSWORD = "...",
}
```

An app password (not the account password) is used so the account password is
never stored and the token can be revoked per-device. Generate one in the web UI
(personal settings → Security → Devices & sessions → *Create new app password*)
or server-side:

```nu
docker exec -u www-data nc-app php occ user:auth-tokens:add cyp --name=<device> -n
```

## Unix branch

Drives headless `nextcloudcmd` (from the `nextcloud-client` package) through a
**system** systemd unit + timer:

1. Writes `/etc/nextcloud-vault.env` (`NC_USER`, `NC_PASSWORD`, root `600`).
2. Writes `/etc/systemd/system/nextcloud-vault.service` (oneshot, `User=<you>`,
   `EnvironmentFile=/etc/nextcloud-vault.env`) and `nextcloud-vault.timer`
   (every 3 min + 2 min after boot).
3. `systemctl enable --now nextcloud-vault.timer`, then runs one sync.

`nextcloudcmd` only syncs the account **root**, so the resolved `vault` folder
maps to the account root (there is no subfolder targeting).

## Windows branch

Uses the Nextcloud desktop client (winget). There is no supported headless
preconfiguration, so logging in and choosing the sync folder is a manual GUI
step.

> The Windows branch has not been run on a Windows machine yet. Treat it as a
> first cut and iterate on the actual box.

## Migration from Seafile

`bootstrap.lua` decommissions an existing Seafile client before starting sync:
if `seaf-cli`/`seaf-daemon` or `~/.ccnet` is present it disables
`seaf-cli@<user>`, removes the `seafile` package (pacman) and deletes
`~/.ccnet` and `~/.local/share/seafile`. This stops the two clients from
fighting over `~/vault`; the vault folder itself is left untouched. Idempotent,
and a no-op on machines that never ran Seafile.

## Ordering

The root bootstrap resolves dependencies **before** module bootstraps, so a fresh
machine installs the client and starts syncing in a single run.
