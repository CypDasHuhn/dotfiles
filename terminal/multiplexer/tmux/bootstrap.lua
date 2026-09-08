local c = require("colors")
local linker = require("linker")

-- Link the config directory (tmuxDotfiles → systemTmux = ~/.config/tmux/)
local ok, err = linker.link_module("tmux")
if ok then
	c.tag_ok("tmux", "linked")
elseif err ~= "already linked" then
	c.tag_err("tmux", err or "failed")
end

-- psmux (Windows) reads ~/.tmux.conf; create that symlink as well so psmux
-- finds the entry point regardless of whether it checks the XDG path.
if linker.machine().os.type == "windows" then
	local ok2, err2 = linker.link_var("tmuxConf", "systemTmuxEntry")
	if ok2 then
		c.tag_ok("tmux", "entry linked (~/.tmux.conf)")
	elseif err2 ~= "already linked" then
		c.tag_err("tmux", err2 or "failed")
	end
end
