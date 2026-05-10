-- Prefer wslview on WSL for OpenBrowser() consumers (e.g. plantuml-previewer).
-- open-browser.vim has WSL support, but its default opener is rundll32; wslview
-- tends to be more reliable for opening Windows default browser from WSL.

if vim.fn.has('wsl') ~= 1 then
  return
end

if vim.fn.executable('wslview') ~= 1 then
  return
end

local function is_list(t)
  return type(t) == 'table' and (#t > 0 or next(t) == nil)
end

local function has_wslview(cmds)
  if not is_list(cmds) then
    return false
  end
  for _, c in ipairs(cmds) do
    if type(c) == 'table' then
      local name = c.name
      local cmd = c.cmd
      if name == 'wslview' or cmd == 'wslview' then
        return true
      end
    end
  end
  return false
end

local wslview_cmd = { name = 'wslview', args = { '{browser}', '{uri}' } }

-- If the user already configured commands, just prepend wslview.
if is_list(vim.g.openbrowser_browser_commands) then
  if not has_wslview(vim.g.openbrowser_browser_commands) then
    table.insert(vim.g.openbrowser_browser_commands, 1, wslview_cmd)
  end
  return
end

-- Otherwise, define a sensible default list with wslview first and the upstream
-- WSL rundll32 fallbacks after it.
vim.g.openbrowser_browser_commands = {
  wslview_cmd,
  {
    name = 'rundll32',
    cmd = '/mnt/c/WINDOWS/System32/rundll32.exe',
    args = { '{browser}', 'url.dll,FileProtocolHandler', '{uri}' },
  },
  {
    name = 'rundll32',
    cmd = '/mnt/c/Windows/System32/rundll32.exe',
    args = { '{browser}', 'url.dll,FileProtocolHandler', '{uri}' },
  },
  {
    name = 'rundll32',
    cmd = 'rundll32.exe',
    args = { '{browser}', 'url.dll,FileProtocolHandler', '{uri}' },
  },
}

