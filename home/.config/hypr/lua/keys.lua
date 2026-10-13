---------------
---- KEYS ----
---------------

-- Modifier tiers.
--
-- Each helper owns one tier of the keymap, so what a bind *means* is decided by
-- the function you call rather than by a modifier string you assemble by hand.
-- The split follows what these modifiers were designed for in tiling WMs:
--
--   super()  acts on me           - focus, navigate, launch
--   shift()  acts on the window   - move it, change its state
--   ctrl()   acts on the system   - hardware, display, session
--   alt()    the alternative take on whatever super()/shift() does on that key
--
-- Two things fall out of this. A misplaced bind is obvious at a glance (a
-- window operation written as super() reads wrong), and each tier has a single
-- place to change if a modifier ever moves.
--
-- Deliberate exceptions, kept because the muscle memory is worth more than the
-- rule: super("Q") to close, the super() mouse drag/resize binds, and alt("V")
-- for clipboard history (Windows' Win + V).
--
-- Every bind also carries a short description, which export() writes out as
-- JSON for the cheatsheet script. Because the description sits on the same line
-- as the bind, the cheatsheet cannot drift from the real keymap.

local M = {}

M.mod = "SUPER" -- the "Windows" key

M.registry = {}

---@param modifiers string full modifier prefix, e.g. "SUPER + SHIFT"
---@param label string short tier name used in the cheatsheet
local function tier(modifiers, label)
	---@param key string
	---@param dispatcher HL.Dispatcher
	---@param desc? string|table description, or the opts table when there is none
	---@param opts? table
	return function(key, dispatcher, desc, opts)
		-- Tolerate the opts table in the third slot, so a bind with options but
		-- no description does not need a nil placeholder.
		if type(desc) == "table" then
			desc, opts = nil, desc
		end

		table.insert(M.registry, {
			tier = label,
			mods = modifiers,
			key = key,
			desc = desc or "",
		})

		return hl.bind(modifiers .. " + " .. key, dispatcher, opts)
	end
end

M.super = tier(M.mod, "Direct")
M.shift = tier(M.mod .. " + SHIFT", "Window")
M.ctrl = tier(M.mod .. " + CTRL", "System")
M.alt = tier(M.mod .. " + ALT", "Alternative")

-- Unmodified keys: the media and Print keys the laptop sends on its own. No
-- tier applies, but they go through here so binds.lua never calls hl.bind
-- directly and they still land in the cheatsheet.
---@param key string
---@param dispatcher HL.Dispatcher
---@param desc? string|table
---@param opts? table
function M.plain(key, dispatcher, desc, opts)
	if type(desc) == "table" then
		desc, opts = nil, desc
	end

	table.insert(M.registry, { tier = "Hardware", mods = "", key = key, desc = desc or "" })

	return hl.bind(key, dispatcher, opts)
end

local function escape(s)
	-- Only the two characters that would break a JSON string. Descriptions are
	-- plain ASCII by convention, so there is nothing else to encode.
	return (s:gsub("\\", "\\\\"):gsub('"', '\\"'))
end

-- Write the registry out for the cheatsheet script. Called at the end of
-- binds.lua, once every bind has registered, and so refreshed on every config
-- reload.
function M.export()
	local dir = os.getenv("HOME") .. "/.cache/hypr"
	os.execute('mkdir -p "' .. dir .. '"')

	local f = io.open(dir .. "/keybinds.json", "w")
	if not f then
		return
	end

	local parts = {}
	for _, b in ipairs(M.registry) do
		local combo = b.mods ~= "" and (b.mods .. " + " .. b.key) or b.key
		parts[#parts + 1] = string.format(
			'{"tier":"%s","combo":"%s","key":"%s","mods":"%s","desc":"%s"}',
			escape(b.tier),
			escape(combo),
			escape(b.key),
			escape(b.mods),
			escape(b.desc)
		)
	end

	f:write("[", table.concat(parts, ","), "]")
	f:close()
end

return M
