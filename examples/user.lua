-- This machine's own settings for Cachypunk. Copied to
-- ~/.config/cachypunk/user.lua on install; that copy is yours and is never
-- touched by updates. Every field is optional: delete what you don't need.
return {
	-- xkb layouts, comma-separated. With several, SUPER + CTRL + K cycles them
	keyboard_layout = "us",

	-- Per-device input settings (names: hyprctl devices)
	devices = {
		-- { name = "logitech-g502", sensitivity = -0.5 },
	},

	-- $BROWSER for CLI tools; leave nil to keep the xdg default
	-- browser = "firefox",

	-- SUPER + <letter> launchers, by .desktop name (ls /usr/share/applications)
	apps = {
		-- B = { desktop = "firefox", name = "Firefox" },
	},

	-- Commands run when Hyprland starts
	autostart = {
		-- "nm-applet",
	},

	-- Commands run at start once the bar's tray exists: for apps that register
	-- their tray icon only once (KeePassXC)
	tray_autostart = {
		-- "gtk-launch org.keepassxc.KeePassXC",
	},
}
