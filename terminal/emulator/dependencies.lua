local h = require("infra.dependencies.helpers")

local function arch_font(name)
	return h.dep({
		unix = {
			arch = {
				command = "sudo pacman -S --noconfirm --needed " .. name,
				verify = "pacman -Q " .. name,
				once = true,
			},
		},
	})
end

return {
	nerd_font = arch_font("ttf-jetbrains-mono-nerd"),
	nerd_symbols_mono = arch_font("ttf-nerd-fonts-symbols-mono"),
	emoji_font = arch_font("noto-fonts-emoji"),
	noto_fonts = arch_font("noto-fonts"),
}
