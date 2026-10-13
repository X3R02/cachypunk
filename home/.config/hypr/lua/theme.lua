-- Border colors from the current theme. theme-set renders
-- ~/.config/theme/hyprland.lua from a matugen template and reloads Hyprland,
-- so this is re-read on every theme switch.
local M = {}

local fallback = {
	active_border = "rgb(00e5ff)",
	inactive_border = "rgba(3a4252aa)",
}

local function load()
	local ok, colors = pcall(dofile, os.getenv("HOME") .. "/.config/theme/hyprland.lua")
	if ok and type(colors) == "table" then
		return colors
	end
	return fallback
end

function M.get_accent()
	return load().active_border or fallback.active_border
end

function M.get_inactive()
	return load().inactive_border or fallback.inactive_border
end

return M
