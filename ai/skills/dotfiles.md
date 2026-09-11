---
name: dotfiles
description: Use when working in this dotfiles repo (~/dotfiles) or on any of its configs — nvim config (also called nvim config / neovim config), shell, terminal emulators, zen browser, lazygit, AutoHotkey, or when adding skills/modules. Explains the Lua-based bootstrap/linker architecture, module layout, and conventions for adding configs or skills.
---

# Dotfiles Architecture

Each module is a directory with a `bootstrap.lua`, executed by the root
`bootstrap.lua` (Lua-based, cross-platform Linux/Windows, entry point:
`lua bootstrap.lua [<filter>]`). A per-machine `.machine.local.lua` next to
`infra/machine.lua` stores machine identity. `infra/` holds the shared
machinery: `machine.lua` (first-run setup), `linker.lua` (symlinks; refuses to
overwrite foreign files), `bootstrapper.lua` (module discovery), `platform.lua`,
`fs.lua`, `resolver.lua`, `filters.lua`, `colors.lua` (tagged output via
`c.tag_ok/tag_warn/...` returns `os`-independent status).

## Modules

- `nvim/` — Lazy-based config; see `nvim/explenation.md` for the full story.
  `init.lua` loads `lua/config` (incl. `lang-packs/<lang>.lua` declaring
  servers/formatters/linters/tools), `lua/plugins/**` specs, `lua/lib` helpers.
- `shell/` — generated configs via `shell/run.lua`: `shell/modules`
  (bash/nushell/pwsh/zsh/shared), mappers, `shell/generated` output
  (profile/path scripts).
- `terminal/` — emulators (kitty, foot, konsole, wezterm, windows-terminal)
  plus multiplexers (tmux, zellij); `emulator/generator.lua` + `keybinds.lua`
  generate per-emulator configs from shared definitions.
- `git/` — gitignore + lazygit.
- `ai/` — shared AI-tool skills and linkers.

## Conventions

- Everything generated is derived from Lua; prefer editing the source module,
  not generated artifacts (`shell/generated`, `out/` dirs).
- Bootstraps are idempotent and skip services not installed on the machine.
- Skills may be authored flat as `ai/skills/<name>.md` or as a standard
  `<name>/SKILL.md` folder when supporting files are needed. The linker
  materializes flat skills as regular `<name>/SKILL.md` files and links folder
  skills into opencode, Claude, Codex, and Copilot CLI skill directories per
  machine.
