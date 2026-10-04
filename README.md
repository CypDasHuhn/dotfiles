# My Dotfiles

More about this proj later.

## Quick setup for new machine

Add user:

```bash
curl -fsSL https://raw.githubusercontent.com/CypDasHuhn/dotfiles/main/infra/bash/server-user-setup.sh | bash -s -- --no-root-login
```

Run install + essentials before bootstrap.lua:

```bash
curl -fsSL https://raw.githubusercontent.com/CypDasHuhn/dotfiles/main/infra/bash/arch-bootstrap.sh | bash -s -- --no-root-login
```
