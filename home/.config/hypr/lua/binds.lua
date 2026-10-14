---------------------
---- KEYBINDINGS ----
---------------------

-- Organised by modifier tier, not by feature. See keys.lua for what each tier
-- means; the short version is:
--
--   SUPER         focus, navigate, launch      (acts on me)
--   SUPER + SHIFT move / restate the window    (acts on the window)
--   SUPER + CTRL  hardware, display, session   (acts on the system)
--   SUPER + ALT   the alternative on that key
--
-- The third argument to each helper is the description that shows up in the
-- cheatsheet (SUPER + K). One convention, so the list reads consistently:
--
--   * Something you summon is named by what it is, with no verb - "Terminal",
--     "Brave", "Clipboard history". No "Launch"/"Open"/"Show" prefixes.
--   * Something you do takes an imperative verb - "Focus left", "Close the
--     window", "Go to workspace 3".
--
-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for the bind syntax.

local k = require("lua.keys")
local progs = require("lua.programs")
local rules = require("lua.rules")

---------------------------------------------------------------------
-- SUPER - focus, navigate, launch
---------------------------------------------------------------------

k.super("RETURN", hl.dsp.exec_cmd(progs.terminal), "Terminal")

-- Nautilus floats when opened here but tiles normally when launched any
-- other way (file associations, the launcher, another app opening a folder).
-- Not exec_cmd rules: those follow the spawned PID, and nautilus stays alive
-- after its last window closes, so the next launch only asks that old
-- process for a window and the rule never matched it (rules.lua)
k.super("E", function()
	rules.float_next_file_manager()
	hl.dispatch(hl.dsp.exec_cmd(progs.file_manager))
end, "File manager (floating)")

k.super("SPACE", hl.dsp.exec_cmd("walker"), "Launcher")

-- Emoji picker. Windows puts this on Win + . and the launcher is already on
-- SUPER + SPACE, so both text-insertion pickers sit on the direct tier.
k.super("PERIOD", progs.walker("symbols"), "Emojis")

-- The cheatsheet reads the JSON that keys.export() writes at the end of this
-- file, so it always lists the binds actually loaded.
k.super("K", hl.dsp.exec_cmd("hypr-keybinds"), "Keybinding cheatsheet")

-- The now-playing panel (any MPRIS player: music, videos, browser tabs). On
-- the direct tier, not with the SUPER + CTRL panels: those are system
-- settings, this is something you summon, like the launcher
k.super("M", progs.panel("media"), "Media player")

-- The notification history, with the Do not disturb switch at its top
k.super("N", progs.panel("notifications"), "Notifications")

-- One bind per app, keyed by the letter in programs.apps.
for key, app in pairs(progs.apps) do
	k.super(key, progs.launch(app.desktop), app.name)
end

-- Focus and window movement are generated together so the two tiers can never
-- disagree about which directions exist.
for _, dir in ipairs({ "left", "right", "up", "down" }) do
	k.super(dir, hl.dsp.focus({ direction = dir }), "Focus " .. dir)
	k.shift(dir, hl.dsp.window.move({ direction = dir }), "Move the window " .. dir)
end

-- Walker's window switcher (elephant "windows" provider): a searchable list of
-- every open window. The directional binds above only reach the current workspace, so this
-- is what crosses workspaces without knowing which one a window ended up on.
k.super("TAB", progs.walker("windows"), "Window switcher")

for i = 1, 10 do
	local key = tostring(i % 10) -- workspace 10 sits on key 0
	k.super(key, hl.dsp.focus({ workspace = i }), "Go to workspace " .. i)
	k.shift(key, hl.dsp.window.move({ workspace = i }), "Move the window to workspace " .. i)
end

-- Scroll through workspaces
k.super("mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Go to the next workspace")
k.super("mouse_up", hl.dsp.focus({ workspace = "e-1" }), "Go to the previous workspace")

-- Scratchpad
k.super("S", hl.dsp.workspace.toggle_special("magic"), "Scratchpad")
k.shift("S", hl.dsp.window.move({ workspace = "special:magic" }), "Move the window to the scratchpad")

-- Closing is a window operation by the tier rule, but SUPER + Q is close to
-- universal muscle memory, so it stays here. Same for the mouse binds below.
k.super("Q", hl.dsp.window.close(), "Close the window")

k.super("mouse:272", hl.dsp.window.drag(), "Drag the window", { mouse = true })
k.super("mouse:273", hl.dsp.window.resize(), "Resize the window", { mouse = true })

---------------------------------------------------------------------
-- SUPER + SHIFT - act on the focused window
---------------------------------------------------------------------
-- Directional moves, workspace moves and the scratchpad move are generated
-- alongside their SUPER counterparts above.

k.shift("V", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
k.shift("P", hl.dsp.window.pseudo(), "Toggle pseudotiling")
k.shift("J", hl.dsp.layout("togglesplit"), "Toggle the split direction (dwindle only)")

-- Fullscreen: the window covers the whole monitor, bar included. mode only
-- accepts "fullscreen" or "maximized"; action only accepts "toggle" - "on"/"off"
-- silently produce no dispatcher.
--
-- Un-fullscreening under scrolling has been reported as unreliable
-- (hyprwm/Hyprland#14494), which is what the SUPER + ALT + F alternative below
-- is for - that one keeps the window tiled.
k.shift("F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), "Toggle fullscreen")

-- Maximize: the window leaves the layout but still respects the area the bar
-- reserves. Under the scrolling layout this is a no-op whenever the workspace
-- has a single column, because scrolling.fullscreen_on_one_column already gives
-- that window the full width.
k.shift("M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), "Maximize the window")

---------------------------------------------------------------------
-- SUPER + CTRL - hardware, display, session
---------------------------------------------------------------------

k.ctrl("L", hl.dsp.exec_cmd("hyprlock"), "Lock the screen")

-- The counterpart to SUPER + CTRL + L: hold hypridle off so the 5 min lock and
-- the DPMS blank never fire. For streaming, where the screen is being watched
-- rather than typed at. Toggles a logind idle inhibitor rather than editing
-- hypridle.conf, so the normal timeouts return as soon as it is switched off.
k.ctrl("I", hl.dsp.exec_cmd("hypridle-toggle"), "Toggle the auto-lock")

k.ctrl(
	"M",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"),
	"Exit Hyprland"
)

-- The bar's session menu (lock, suspend, log out, restart, shut down)
k.ctrl("P", progs.panel("power"), "Power menu")

k.ctrl("N", hl.dsp.exec_cmd("hyprsunset-toggle"), "Toggle the night light")

-- Cycle the xkb layout on every keyboard at once, through the layouts set in
-- user.lua (keyboard_layout); the script is what flips them, because hl.dsp
-- has no dispatcher for xkb.
k.ctrl("K", hl.dsp.exec_cmd("hypr-kblayout-toggle"), "Switch the keyboard layout")

-- The bar's panels; nm-connection-editor, bluetui and wiremix are each
-- behind their panel's "Advanced" row (battery has none)
k.ctrl("W", progs.panel("network"), "Network settings")
k.ctrl("B", progs.panel("bluetooth"), "Bluetooth settings")
k.ctrl("A", progs.panel("volume"), "Audio settings")
-- E for energy: B and P are taken by bluetooth and the power menu
k.ctrl("E", progs.panel("battery"), "Battery settings")
-- The system's look: the colour theme switcher
k.ctrl("T", progs.themes(), "Theme switcher")
k.ctrl("D", progs.wallpapers(), "Wallpaper picker")
k.ctrl("C", progs.tui("btop"), "System monitor")

---------------------------------------------------------------------
-- SUPER + ALT - alternatives
---------------------------------------------------------------------

-- Alternative to SUPER + SHIFT + F: widen the focused column to the full screen
-- width. Unlike fullscreen (or maximize on SUPER + SHIFT + M) this keeps the
-- window tiled, so the bar and the gaps stay put. 1.0 is also one of the presets in scrolling.explicit_column_widths.
k.alt("F", hl.dsp.layout("colresize 1.0"), "Widen the column to full width (stays tiled)")

-- Alternative to SUPER + E: find a file by name rather than browse to it. Same
-- target, opposite approach - you already know what you want.
k.alt("E", progs.walker("files"), "File search")

-- Clipboard history. On the ALT tier by choice rather than by the tier rule:
-- Windows puts this on Win + V and macOS pastes with Cmd + V, so V is where the
-- hand already goes. It is not an alternative to SUPER + SHIFT + V (float).
k.alt("V", progs.walker("clipboard"), "Clipboard history")

-- Alternative to Print: grab a colour off the screen rather than an image.
-- -l gives lowercase hex (CSS-friendly), -n sends a notification.
k.alt("Print", hl.dsp.exec_cmd("hyprpicker -a -f hex -l -n"), "Pick a colour as hex")

---------------------------------------------------------------------
-- Screenshots
---------------------------------------------------------------------
-- Print is a key the laptop sends on its own, so the modifiers here select the
-- capture target rather than a tier: bare opens the editor, SUPER goes straight
-- to the clipboard, SUPER + ALT picks a colour instead (above). theme-slurp is
-- slurp with the theme's colours (~/.config/theme/slurp.args).

-- The bare capture lands on the clipboard the moment it is taken, before the
-- editor opens; an annotated version is copied from satty (Ctrl+C). No
-- --auto-copy: it copies after every stroke, and each copy would be a new
-- entry in the clipboard history.
k.plain(
	"Print",
	hl.dsp.exec_cmd(
		'f=$(mktemp --suffix=.png) && grim -g "$(~/.local/bin/theme-slurp -d)" "$f" && wl-copy -t image/png < "$f" && '
			.. 'satty -f "$f" --copy-command wl-copy -o "~/Pictures/Screenshots/%Y%m%d_%H%M%S.png"; rm -f "$f"'
	),
	"Screenshot a region, then edit"
)
k.super("Print", hl.dsp.exec_cmd('grim -g "$(~/.local/bin/theme-slurp -d)" - | wl-copy'), "Screenshot a region to the clipboard")

---------------------------------------------------------------------
-- Laptop hardware keys
---------------------------------------------------------------------
-- Volume, microphone and brightness go through the quickshell OSD
-- (`qs ipc call osd ...`), which changes the level and shows it. Each step
-- lands on a multiple of 5, so the OSD's 20-block meter always ends on a
-- whole block. locked = true keeps them working on the lock screen.

k.plain("XF86AudioRaiseVolume", hl.dsp.exec_cmd("qs ipc call osd volume up"), "Volume up", { locked = true, repeating = true })
k.plain("XF86AudioLowerVolume", hl.dsp.exec_cmd("qs ipc call osd volume down"), "Volume down", { locked = true, repeating = true })

-- Toggles must not repeat: holding the key would flip the state an even
-- number of times and land back where it started.
k.plain("XF86AudioMute", hl.dsp.exec_cmd("qs ipc call osd volume mute"), "Mute output", { locked = true })
k.plain("XF86AudioMicMute", hl.dsp.exec_cmd("qs ipc call osd mic"), "Mute the microphone", { locked = true })

k.plain("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs ipc call osd brightness up"), "Brightness up", { locked = true, repeating = true })
k.plain("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs ipc call osd brightness down"), "Brightness down", { locked = true, repeating = true })

-- Requires playerctl
k.plain("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), "Next track", { locked = true })
k.plain("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause", { locked = true })
k.plain("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause", { locked = true })
k.plain("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), "Previous track", { locked = true })

-- Must stay last: writes the cheatsheet JSON once every bind above has
-- registered.
k.export()
