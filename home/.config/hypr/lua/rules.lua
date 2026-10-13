local floating = require("lua.floating")
local progs = require("lua.programs")

local M = {}

-- Class comes from programs.lua, which is also what programs.tui() launches
-- with, so the rule and the binds cannot drift apart.
hl.window_rule({
	name = "floatterm",
	match = { class = progs.float_term_class },
	float = true,
	size = floating.compact,
})

hl.window_rule({
	name = "float-nm",
	match = { class = "nm-connection-editor" },
	float = true,
	size = floating.compact,
})

-- The screenshot annotator gets the working size: you draw in it for a stretch,
-- and at 900x600 the canvas was the cramped part of taking a screenshot.
--
-- Satty would otherwise size itself to the captured image, so a fixed size can
-- fight the region's aspect ratio. If that ever grates, satty 0.21 has
-- `--resize smart` and `--input-scale` (the latter matters on this 1.5x panel) -
-- pass them in the Print bind and drop the size here.
hl.window_rule({
	name = "float-satty",
	match = { class = "com.gabm.satty" },
	float = true,
	size = floating.large,
})

-- KeePassXC is always consulted on top of something else - you go looking for it
-- while already working in a browser or an editor - so tiling it just shoves that
-- work aside. Floating puts it over the task instead.
--
-- Matched by class rather than from a bind (the way the file manager is done)
-- because it has no launch bind: it starts into the tray at login and is summoned
-- from there, from a browser, or by autotype. The rule has to hold for all of
-- those, not for one keystroke.
--
-- Two spellings because 2.7.12 calls setDesktopFileName, so the Wayland app_id
-- comes from the desktop entry, while under XWayland the class is the
-- StartupWMClass. Nothing else on the system has keepassxc in its class, so
-- covering both costs nothing. Narrow it with:
--   hyprctl clients -j | jq -r '.[] | select(.class|test("(?i)keepass")) | .class'
--
-- Split in two on purpose. The class matches every KeePassXC window, including
-- the unlock prompt and the browser access requests the Brave extension triggers,
-- and stretching those to a working size would be worse than leaving them alone.
-- Those are modal, the main window is not, so `modal = false` applies the size to
-- the main window only while both rules still float.
local keepassxc = "^(org\\.keepassxc\\.KeePassXC|keepassxc)$"

hl.window_rule({
	name = "float-keepassxc",
	match = { class = keepassxc },
	float = true,
})

hl.window_rule({
	name = "size-keepassxc-main",
	match = { class = keepassxc, modal = false },
	size = floating.large,
})

-- The screen-share picker the portal opens (OBS, screen sharing in calls...)
hl.window_rule({
	name = "float-share-picker",
	match = { class = "hyprland-share-picker" },
	float = true,
	size = floating.compact,
})

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- The file manager floats only when SUPER + E opens it (binds.lua). A class
-- rule, disabled until that bind arms it: it switches itself off as soon as
-- the next nautilus window opens, or after 5 s if none does, so nautilus
-- opened any other way still tiles. A rule passed to exec_cmd can't do this:
-- it follows the spawned PID, and a nautilus already running in the
-- background serves the new window from its own process.
local file_manager_once = hl.window_rule({
	name = "float-file-manager-once",
	match = { class = progs.file_manager_class },
	float = true,
	size = floating.compact,
})
file_manager_once:set_enabled(false)

hl.on("window.open", function(window)
	if window and window.class == progs.file_manager_class then
		file_manager_once:set_enabled(false)
	end
end)

function M.float_next_file_manager()
	file_manager_once:set_enabled(true)
	hl.timer(function()
		file_manager_once:set_enabled(false)
	end, { timeout = 5000, type = "oneshot" })
end

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

return M
