-- WSL: plantuml-previewer delegates to open-browser.vim, which converts filepaths
-- into a file:// URI and (on WSL) runs `wslpath -am` first. That combination can
-- yield a file URI that Windows doesn't open reliably.
--
-- Workaround: override :PlantumlOpen on WSL to call `wslview` with the raw Linux
-- path to the viewer HTML instead of going through OpenBrowser().

if vim.fn.has('wsl') ~= 1 then
  return
end

if vim.fn.executable('wslview') ~= 1 then
  return
end

local function viewer_index_html()
  local viewer_path = vim.g['plantuml_previewer#viewer_path']
  if viewer_path == nil or viewer_path == 0 or viewer_path == '0' then
    if vim.fn.exists('*plantuml_previewer#default_viewer_path') == 1 then
      viewer_path = vim.fn['plantuml_previewer#default_viewer_path']()
    end
  end
  if type(viewer_path) ~= 'string' or viewer_path == '' then
    return nil
  end
  return viewer_path .. '/index.html'
end

local function plantuml_open_wsl()
  local function try_start()
    return pcall(function()
      return vim.fn['plantuml_previewer#start']()
    end)
  end

  -- First attempt: trigger Vim's autoload (works if plugin is already on rtp).
  local ok_call, ok_start = try_start()

  if not ok_call then
    -- Second attempt: force-load via lazy.nvim, then retry.
    local ok_lazy, lazy = pcall(require, 'lazy')
    if ok_lazy and type(lazy.load) == 'function' then
      pcall(lazy.load, { plugins = { 'plantuml-previewer.vim' } })
    end
    ok_call, ok_start = try_start()
  end

  if not ok_call then
    vim.notify(
      ('plantuml-previewer: could not start (ft=%s, buf=%s)'):format(vim.bo.filetype, vim.api.nvim_buf_get_name(0)),
      vim.log.levels.WARN
    )
    return
  end

  if not ok_start then
    return
  end

  local index = viewer_index_html()
  if not index then
    vim.notify('plantuml-previewer: could not determine viewer index.html path', vim.log.levels.ERROR)
    return
  end

  -- Detach so Neovim doesn't block.
  vim.fn.jobstart({ 'wslview', index }, { detach = true })
end

-- Use :command! so we override the plugin's command definition (which is created
-- when the plugin is lazy-loaded on FileType=plantuml).
_G.__plantuml_open_wsl = plantuml_open_wsl

local function define_cmd()
  vim.cmd('command! PlantumlOpen lua _G.__plantuml_open_wsl()')
end

define_cmd()

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'plantuml',
  callback = function()
    -- Ensure our override runs after lazy loaders / plugin ft handlers.
    vim.schedule(define_cmd)
  end,
})
