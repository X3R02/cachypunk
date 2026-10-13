---------------
---- INPUT ----
---------------

local user = require("lua.user")

hl.config({
	input = {
		-- From ~/.config/cachypunk/user.lua (keyboard_layout), "us" by default.
		-- With several, listed in the order switchxkblayout indexes them;
		-- SUPER + CTRL + K cycles between them via hypr-kblayout-toggle.
		kb_layout = user.keyboard_layout,
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,

		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = false,
		},
	},
})

-- Per-device settings (a mouse's own sensitivity) come from user.lua
for _, device in ipairs(user.devices) do
	hl.device(device)
end

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})
