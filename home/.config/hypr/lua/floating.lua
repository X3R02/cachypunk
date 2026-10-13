------------------
---- FLOATING ----
------------------

-- Size presets for the windows that open floating, so the class rules in
-- rules.lua and the per-bind exec rules in binds.lua can't drift apart.
--
-- Values are LOGICAL pixels, not physical. This panel is 1920x1200 at scale 1.5,
-- so the desk is 1280x800 and the bar takes 32 off the top - about 1280x768 to
-- play with. Both presets leave a visible margin inside that rather than filling
-- it, which is rather the point of a floating window: you can still see what it
-- is sitting on top of.
--
-- Percentages ("85% 88%") are accepted by the rule parser too and would survive
-- an external monitor better, but the parser accepting a string is not proof it
-- resolves correctly, so these stay in pixels - which is what this config has
-- been running on.
--
-- Note the two mechanisms that consume these are not interchangeable:
--   * rules.lua matches by class, so the app floats however it is launched.
--   * exec_cmd rules only touch the window that bind spawns, which is what we
--     want for a general-purpose app like the file manager - opening a folder
--     from another app should still tile.

local M = {}

-- Glance and dismiss: TUIs, pickers, connection editors, the file manager. Big
-- enough to read, small enough that the window underneath stays obvious.
M.compact = "900 600"

-- Apps you actually work inside for a stretch while something else is underneath.
M.large = "1100 680"

return M
