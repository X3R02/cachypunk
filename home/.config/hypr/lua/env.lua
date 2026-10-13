-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

local user = require("lua.user")

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Qt apps have no equivalent of the portal's color-scheme, so without a
-- platform theme they render light. qt6ct covers Qt6 (dolphin); Qt5 apps
-- resolve the plugin name against their own plugin dir, so a Qt5 app needs
-- QT_QPA_PLATFORMTHEME=qt5ct in its own launcher (.desktop override).
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- CLI tools (gh, python's webbrowser, git web--browse) read $BROWSER instead
-- of the xdg default; user.lua sets it to the same browser as mimeapps.list.
if user.browser then
	hl.env("BROWSER", user.browser)
end

-- git, sudoedit, crontab and friends fall back to vi/nano; neovim is the
-- editor this setup themes.
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
