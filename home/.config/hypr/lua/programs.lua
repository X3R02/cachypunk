-------------------
---- PROGRAMS ----
-------------------

-- Which programs the binds resolve to. Kept out of binds.lua so that file stays
-- a pure keymap: swapping a terminal or a browser is a one-line change here and
-- every bind that uses it follows.

local M = {}

M.terminal = "ghostty"
M.file_manager = "nautilus"
-- Its Wayland app id; rules.lua floats the window SUPER + E opens by it
M.file_manager_class = "org.gnome.Nautilus"

-- Class for the small floating terminal panels. rules.lua matches on it, so
-- both sides read the same value and can't drift apart.
M.float_term_class = "com.floatterm"

-- Apps on the launch tier, keyed by the letter they get under SUPER. The name is
-- what the keybinding cheatsheet shows; desktop is the .desktop entry.
--
-- Going through gtk-launch rather than the raw binary keeps the .desktop files as
-- the single source of truth, so the local overrides still apply: the Brave
-- profile and app mode for the web apps, the Qt5 theme for KeePassXC, the
-- scaling env for Steam.
-- They are personal, so they come from ~/.config/cachypunk/user.lua (apps).
M.apps = require("lua.user").apps

---@param desktop string .desktop entry name, without the extension
---@return HL.Dispatcher
function M.launch(desktop)
	return hl.dsp.exec_cmd("gtk-launch " .. desktop)
end

-- Walker restricted to one elephant provider, by the name `elephant
-- listproviders` prints. Walker runs as a service (autostart.lua), so this
-- opens instantly; calling it again while open closes it (close_when_open).
---@param provider string elephant provider, e.g. "clipboard"
---@return HL.Dispatcher
function M.walker(provider)
	return hl.dsp.exec_cmd("walker -m " .. provider)
end

-- A TUI in a floating terminal. The class is what makes it float (rules.lua),
-- so these come up as small centered panels rather than tiling into the layout.
---@param cmd string command to run inside the terminal
---@return HL.Dispatcher
function M.tui(cmd)
	return hl.dsp.exec_cmd(M.terminal .. " --class=" .. M.float_term_class .. " -e " .. cmd)
end

-- A quickshell bar panel (wifi, bluetooth, audio, battery, power) on the
-- focused monitor; pressing it again closes it. Each panel's full tool sits
-- behind its own "Advanced" row, so binds open the panel, not the tool.
---@param name string panel name, as in `qs ipc call panel toggle <name>`
---@return HL.Dispatcher
function M.panel(name)
	return hl.dsp.exec_cmd("qs ipc call panel toggle " .. name)
end

-- The quickshell theme switcher: a carousel of the palettes in
-- ~/.config/matugen/themes, applied through theme-set.
---@return HL.Dispatcher
function M.themes()
	return hl.dsp.exec_cmd("qs ipc call themes toggle")
end

-- The wallpaper picker: the current theme's image, from <pictures>/wallpapers
-- or the palette's own, applied through wallpaper-set.
function M.wallpapers()
	return hl.dsp.exec_cmd("qs ipc call wallpapers toggle")
end

return M
