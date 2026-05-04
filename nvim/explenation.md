# Explenation of Nvim Config Setup

## General

Hi! My nvim setup is modular and completely indirect.
How great! Things are decoupled and rather search for something instead of being declared it.

Look at the `init.lua`, it declares almost nothing, But it does declare 2-3 things.
It defines:

- Load all files of `/lua/config`
  - These have general settings f.e. key-rebinds, or behaviour like folding and yanking.
- We use the package manager `lazy`
- We want to load all lazy plugins defined in `/lua/plugins`

The only directory left uncovered, ignoring sub folders, is `/lua/lib`.
In short, that directory just has functions which are to big to be somewhere else.
F.e. A lot of custom Neotree (our file-explorer) functions live there.

## Lang Packs

Language support is also modular. `/lua/config/lang-packs/` holds one file per language (or language group).
Each file just returns a table declaring what that language needs:

```lua
return {
  servers    = { ... },  -- LSP servers (configured via lspconfig)
  formatters = { ... },  -- formatters (used by conform.nvim)
  linters    = { ... },  -- linters (used by nvim-lint)
  tools      = { ... },  -- extra Mason tools to install
  treesitter = { ... },  -- treesitter parsers
}
```

The `init.lua` in that folder scans all sibling files, merges them into one big table, and returns it.
Plugins like `lsp-config.lua` and `autoformat.lua` then just `require` that merged table to know what to set up.
So to add a new language you drop a file in `lang-packs/` — nothing else needs to be touched.

## Plugin Directory Structure

`/lua/plugins/` is also fully auto-discovered. Every `.lua` file in there (recursively) is expected to return a lazy plugin spec or a list of them.
The `init.lua` in that folder collects all of them and hands the flat list to `lazy`.

The folders are organized by rough purpose:

- `editor/` — things that change how editing feels (LSP, autoformat, autopairs, treesitter, …)
- `movement/` — things that change how you navigate (telescope, neo-tree, harpoon, bufferline, …)
- `stacks/` — tooling for specific tech stacks or workflows (dotnet, git, markdown, latex, …)
- `misc/` — everything else that doesn't fit cleanly above

## bootstrap.lua and dependencies.lua

These two files are **not part of the Neovim config itself** — you can ignore them entirely if you just want to use this config.

They exist for the broader dotfiles setup system. The short version:

- `dependencies.lua` declares that this module depends on `nvim` (the Neovim binary) being installed, in a format the dotfiles installer understands.
- `bootstrap.lua` tells the dotfiles installer to symlink this nvim config into the right place (`~/.config/nvim` or equivalent).

Think of them as install metadata for the outer dotfiles tooling, not config for Neovim itself.
