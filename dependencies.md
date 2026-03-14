# Dependency System

## Core idea

Declare dependencies by name, with OS/distro/arch-specific install commands.
Uses condition-based resolution instead of explicit priorities.

## Schema (implicit defaults at every level)

```lua
-- Shortest: universal command tool = "npm install -g foo"
-- OS level
tool = { unix = "cmd", windows = "cmd" }

-- Distro level (arch, ubuntu, default...)
tool = { unix = { arch = "pacman -S foo", ubuntu = "apt install foo" } }

-- CPU architecture level (x86_64, aarch64, default...)
tool = { unix = { arch = { x86_64 = "cmd", aarch64 = "cmd-arm" } } }

-- With condition (checked before running)
tool = { unix = { arch = { command = "cmd", condition = "which dep" } } }
```

## Helpers

```lua
neovim = vanilla("neovim", "Neovim.Neovim")
prettier = npm("prettier")
black = pipx("black")
stylua = cargo("stylua")
```

## Resolution

Two buckets: `todo` and `delayed`. Each cycle:

1. Pop from todo, check condition
2. If met → run command
3. If not → move to delayed
4. When todo empty, swap delayed → todo
5. Max cycles prevents infinite loops

## Usage

Place `dependencies.lua` files anywhere, they're auto-imported.
Run with: `lua dependencies/run.lua [base_path] [max_cycles]`
