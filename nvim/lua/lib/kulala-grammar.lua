-- Repair a stuck kulala.nvim tree-sitter grammar checkout.
--
-- kulala fetches and builds its own HTTP grammar into a git repository under
-- stdpath('data')/kulala.nvim/tree-sitter-kulala-http. Its fetcher
-- (kulala/config/parser.lua) takes a fast path whenever a `.git` directory
-- already exists: it runs `git fetch origin` without first verifying that a
-- remote is configured.
--
-- So if a run is interrupted after `git init` but before `git remote add
-- origin` (or the remote is otherwise lost), the checkout is permanently
-- stuck and every editor start prints:
--
--   Failed to fetch tree-sitter grammar: fatal: 'origin' does not appear to
--   be a git repository
--
-- kulala exposes no option to recover, and patching the installed plugin does
-- not survive updates. The portable fix is to repair the directory before
-- setup(): if it is a git repo without an `origin` remote, remove it so
-- kulala re-initialises it from its own constant (Globals.TREESITTER_REPO_URL).

local M = {}

local function grammar_dir()
  return vim.fs.joinpath(vim.fn.stdpath 'data', 'kulala.nvim', 'tree-sitter-kulala-http')
end

local function has_origin(dir)
  vim.fn.system { 'git', '-C', dir, 'remote', 'get-url', 'origin' }
  return vim.v.shell_error == 0
end

--- Removes a broken grammar checkout so kulala can rebuild it.
--- @return boolean repaired
function M.repair()
  local dir = grammar_dir()

  if vim.fn.isdirectory(vim.fs.joinpath(dir, '.git')) == 0 or has_origin(dir) then
    return false
  end

  vim.fn.delete(dir, 'rf')
  vim.notify(
    'Removed a stuck kulala tree-sitter grammar checkout (missing origin); it will be rebuilt.',
    vim.log.levels.WARN,
    { title = 'kulala' }
  )
  return true
end

return M
