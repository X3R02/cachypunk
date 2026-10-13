--------------
---- USER ----
--------------

-- Per-machine settings: ~/.config/cachypunk/user.lua, outside the repo, so a
-- keyboard layout or a personal app never ends up in the shared config. That
-- file returns a table; every field is optional and falls back to the default
-- below. See examples/user.lua in the cachypunk repo for all of them.
--
-- A missing file is fine. A file with an error is not hidden: dofile raises,
-- and Hyprland reports it like any other config error.

local defaults = {
	-- xkb layouts, comma-separated; SUPER + CTRL + K cycles through them
	keyboard_layout = "us",
	-- Extra hl.device() specs (per-mouse sensitivity and the like)
	devices = {},
	-- $BROWSER for CLI tools; nil leaves the xdg default alone
	browser = nil,
	-- SUPER + <letter> launchers: { B = { desktop = "brave-origin", name = "Brave" } }
	apps = {},
	-- Commands run at Hyprland start
	autostart = {},
	-- Commands run at start once the bar's tray exists (apps that register a
	-- tray icon once and never retry, like KeePassXC)
	tray_autostart = {},
}

local path = os.getenv("HOME") .. "/.config/cachypunk/user.lua"
local user = {}
local f = io.open(path, "r")
if f then
	f:close()
	user = dofile(path) or {}
end

return setmetatable(user, { __index = defaults })
