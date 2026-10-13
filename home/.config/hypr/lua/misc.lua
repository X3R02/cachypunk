----------------
----  MISC  ----
----------------

hl.config({
	misc = {
		-- quickshell draws the wallpaper; no mascot or logo flashing before it
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		-- Any key or mouse movement turns a blanked screen back on, without
		-- waiting on hypridle's on-resume (input on the lock screen doesn't
		-- reach it)
		key_press_enables_dpms = true,
		mouse_move_enables_dpms = true,
	},
})
