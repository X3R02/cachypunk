------------------
---- XWAYLAND ----
------------------

-- See https://wiki.hypr.land/Configuring/Variables/#xwayland

-- With a fractional monitor scale (1.5 here), XWayland apps are rendered at 1x
-- and then upscaled by the compositor, which makes them look blurry/pixelated
-- (Steam is X11-only, so it's the main victim).
-- force_zero_scaling makes them render at native resolution instead, so they
-- stay sharp. The trade-off: their UI comes out small unless the app scales
-- itself - see the Steam launcher override in
-- ~/.local/share/applications/steam.desktop (STEAM_FORCE_DESKTOPUI_SCALING).
hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})
