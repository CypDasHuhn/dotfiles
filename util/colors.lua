-- ANSI color utilities for terminal output
-- Works in zsh/bash on Unix; falls back to plain text on Windows

local M = {}

local no_color = os.getenv("NO_COLOR") or os.getenv("TERM") == "dumb"

local function ansi(code)
	if no_color then return "" end
	return "\27[" .. code .. "m"
end

local reset = ansi("0")
local bold  = ansi("1")

M.colors = {
	red     = ansi("31"),
	green   = ansi("32"),
	yellow  = ansi("33"),
	blue    = ansi("34"),
	magenta = ansi("35"),
	cyan    = ansi("36"),
	white   = ansi("37"),
	gray    = ansi("90"),
}

function M.color(c, text)
	return (M.colors[c] or "") .. text .. reset
end

function M.bold(text)
	return bold .. text .. reset
end

-- Styled print helpers
function M.header(text)
	print(bold .. ansi("36") .. "=== " .. text .. " ===" .. reset)
end

function M.section(text)
	print(bold .. ansi("34") .. "--- " .. text .. " ---" .. reset)
end

function M.info(text)
	print(ansi("37") .. text .. reset)
end

function M.ok(text)
	print(ansi("32") .. "  ✓ " .. text .. reset)
end

function M.warn(text)
	print(ansi("33") .. "  ! " .. text .. reset)
end

function M.err(text)
	print(ansi("31") .. "  ✗ " .. text .. reset)
end

function M.dim(text)
	print(ansi("90") .. text .. reset)
end

-- Derive a vivid, unique RGB color from a name string using HSV hashing
local function name_to_rgb(name)
	local h = 0
	for i = 1, #name do
		h = (h * 31 + string.byte(name, i)) % 360
	end
	-- HSV → RGB with fixed S=0.75, V=1.0 for vivid but not blinding colors
	local s, v = 0.75, 1.0
	local cv = v * s
	local x  = cv * (1 - math.abs((h / 60) % 2 - 1))
	local m  = v - cv
	local r, g, b
	if     h < 60  then r, g, b = cv, x,  0
	elseif h < 120 then r, g, b = x,  cv, 0
	elseif h < 180 then r, g, b = 0,  cv, x
	elseif h < 240 then r, g, b = 0,  x,  cv
	elseif h < 300 then r, g, b = x,  0,  cv
	else                r, g, b = cv, 0,  x
	end
	return math.floor((r + m) * 255), math.floor((g + m) * 255), math.floor((b + m) * 255)
end

local function name_ansi(name)
	if no_color then return "" end
	local r, g, b = name_to_rgb(name)
	return string.format("\27[38;2;%d;%d;%dm", r, g, b)
end

-- [name] prefix in the name's unique color, followed by plain text
function M.tag(name, text)
	print(name_ansi(name) .. "[" .. name .. "]" .. reset .. " " .. text)
end

-- [name] ✓ text  (name colored, checkmark + text in green)
function M.tag_ok(name, text)
	print(name_ansi(name) .. "[" .. name .. "]" .. reset
		.. ansi("32") .. " ✓ " .. (text or "ok") .. reset)
end

-- [name] ✗ text  (name colored, x + text in red)
function M.tag_err(name, text)
	print(name_ansi(name) .. "[" .. name .. "]" .. reset
		.. ansi("31") .. " ✗ " .. (text or "failed") .. reset)
end

-- [name] ! text  (name colored, ! + text in yellow)
function M.tag_warn(name, text)
	print(name_ansi(name) .. "[" .. name .. "]" .. reset
		.. ansi("33") .. " ! " .. (text or "") .. reset)
end

return M
