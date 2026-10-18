-- Live colour preview: type a hex code after walker's "#" prefix and the
-- swatch updates as you type. Enter copies the selected format.
Name = "colors"
NamePretty = "Colors"
Icon = "color-select"
Action = "wl-copy -- '%VALUE%'"
FixedOrder = true
HideFromProviderlist = false
Description = "preview a hex colour"

local dir = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/elephant-colors"

-- Accepts RGB, RGBA, RRGGBB and RRGGBBAA, with or without the leading "#".
local function parse(query)
	local hex = query:gsub("^%s*#?", ""):gsub("%s+$", ""):lower()
	if not hex:match("^%x+$") then
		return nil
	end
	if #hex == 3 or #hex == 4 then
		hex = hex:gsub("%x", "%0%0")
	end
	if #hex ~= 6 and #hex ~= 8 then
		return nil
	end
	local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	local a = #hex == 8 and tonumber(hex:sub(7, 8), 16) or nil
	return hex, r, g, b, a
end

local function hsl(r, g, b)
	r, g, b = r / 255, g / 255, b / 255
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local l = (max + min) / 2
	local h, s = 0, 0
	if max ~= min then
		local d = max - min
		s = l > 0.5 and d / (2 - max - min) or d / (max + min)
		if max == r then
			h = (g - b) / d + (g < b and 6 or 0)
		elseif max == g then
			h = (b - r) / d + 2
		else
			h = (r - g) / d + 4
		end
		h = h * 60
	end
	return math.floor(h + 0.5), math.floor(s * 100 + 0.5), math.floor(l * 100 + 0.5)
end

-- Swatch with the desktop's card shape (only the bottom-right corner cut).
-- A checkerboard underneath makes transparency visible.
local function swatch(hex, a)
	local path = dir .. "/" .. hex .. ".svg"
	local f = io.open(path, "r")
	if f then
		f:close()
		return path
	end
	os.execute("mkdir -p '" .. dir .. "'")
	f = io.open(path, "w")
	if not f then
		return nil
	end
	local opacity = a and string.format("%.3f", a / 255) or "1"
	f:write(string.format([[
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <defs>
    <pattern id="c" width="32" height="32" patternUnits="userSpaceOnUse">
      <rect width="32" height="32" fill="#cccccc"/>
      <rect width="16" height="16" fill="#777777"/>
      <rect x="16" y="16" width="16" height="16" fill="#777777"/>
    </pattern>
    <clipPath id="k"><polygon points="0,0 256,0 256,208 208,256 0,256"/></clipPath>
  </defs>
  <g clip-path="url(#k)">
    <rect width="256" height="256" fill="url(#c)"/>
    <rect width="256" height="256" fill="#%s" fill-opacity="%s"/>
  </g>
</svg>
]], hex:sub(1, 6), opacity))
	f:close()
	return path
end

function GetEntries(query)
	local hex, r, g, b, a = parse(query or "")
	if not hex then
		return {}
	end
	local h, s, l = hsl(r, g, b)
	local icon = swatch(hex, a)
	local formats
	if a then
		local alpha = string.format("%.2f", a / 255):gsub("0+$", ""):gsub("%.$", "")
		formats = {
			{ "#" .. hex:upper(), "hex" },
			{ string.format("rgba(%d, %d, %d, %s)", r, g, b, alpha), "rgba" },
			{ string.format("hsla(%d, %d%%, %d%%, %s)", h, s, l, alpha), "hsla" },
		}
	else
		formats = {
			{ "#" .. hex:upper(), "hex" },
			{ string.format("rgb(%d, %d, %d)", r, g, b), "rgb" },
			{ string.format("hsl(%d, %d%%, %d%%)", h, s, l), "hsl" },
		}
	end
	local entries = {}
	for _, fmt in ipairs(formats) do
		table.insert(entries, {
			Text = fmt[1],
			Subtext = "copy " .. fmt[2],
			Value = fmt[1],
			Icon = icon,
			Preview = icon,
			PreviewType = "file",
			-- The typed text must always match, or elephant's fuzzy filter drops
			-- the rgb/hsl rows.
			Keywords = { query },
		})
	end
	return entries
end
