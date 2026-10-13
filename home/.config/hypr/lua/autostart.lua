-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

local user = require("lua.user")

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
	-- elephant is the data backend walker queries; walker as a service keeps
	-- the launcher instant. Launched here rather than via their systemd units:
	-- graphical-session.target never starts without uwsm.
	hl.exec_cmd("elephant")
	hl.exec_cmd("walker --gapplication-service")
	hl.exec_cmd("hypridle")
	-- The shell: bar, panels, OSD, notifications, wallpaper and the polkit agent
	hl.exec_cmd("qs")
	hl.exec_cmd("hyprsunset --identity")

	-- This machine's own apps, from ~/.config/cachypunk/user.lua
	for _, cmd in ipairs(user.autostart) do
		hl.exec_cmd(cmd)
	end

	-- Everything here is launched at once, so a tray app can easily come up
	-- before the quickshell bar has claimed org.kde.StatusNotifierWatcher on
	-- D-Bus. Some (KeePassXC) register once and never retry, so they would
	-- start fine but show no tray icon: wait for the watcher first.
	for _, cmd in ipairs(user.tray_autostart) do
		hl.exec_cmd(
			"sh -c 'until busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1; "
				.. "do sleep 0.2; done; exec " .. cmd .. "'"
		)
	end
end)
