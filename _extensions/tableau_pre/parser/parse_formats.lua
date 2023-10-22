local _module_0 = { }
local dump, expect
do
	local _obj_0 = require("parser.util")
	dump, expect = _obj_0.dump, _obj_0.expect
end
local color_names <const> = {
	shade = 1,
	shade1 = 1,
	shade2 = 1,
	shade3 = 1,
	shade4 = 1,
	shade5 = 1,
	shade6 = 1,
	shade7 = 1,
	shade8 = 1,
	shade9 = 1
}
local color_hx3 <const> = "#%x%x%x"
local color_hx6 <const> = "#%x%x%x%x%x%x"
local gather_one_colspec
gather_one_colspec = function()
	return "to be defined below"
end
local named_color
named_color = function(text)
	text:save_place()
	local name = text:scan("%w+%f[%W]")
	if not (name and color_names[name]) then
		text:restore_place()
		return nil
	end
	local suffix = tonumber(text:scan("%d%f[%D]"))
	return {
		color_type = "named-color",
		name = name,
		suffix = suffix
	}
end
local known_color
known_color = function(text)
	local rgb = text:scan(color_hx6) or text:scan(color_hx3)
	if rgb then
		return {
			color_type = "rgb",
			name = rgb
		}
	else
		return named_color(text)
	end
end
local any_color
any_color = function(text)
	local col = text:scan("[%w%-%_]+%f[^%w%-%_]")
	if col then
		return {
			color_type = "any-color",
			name = col
		}
	end
end
local align
align = function(text)
	local spec = nil
	if text:scan("align%(") then
		spec = expect(align, text, "expecting alignment specifier [lcrj][tmb]")
		text:expect("%)", "expected closing parenthesis after alignment specifier")
	else
		if text:scan("[lcrj][tmb]%f[%A]") or text:scan("[lcrj]%f[%A]") or text:scan("[tmb]%f[%A]") then
			spec = {
				type = "align",
				spec = text.last_match
			}
		end
	end
	return spec
end
local boxed
boxed = function(text)
	if text:scan("boxed%f[%A]") or text:scan("box%f[%A]") then
		return {
			type = "boxed"
		}
	end
end
local cols
cols = function(text)
	if not text:scan("cols?%(%s*") then
		return
	end
	local specs = { }
	local spec = gather_one_colspec(text)
	while spec do
		specs[#specs + 1] = spec
		text:skip("%s*,%s*")
		spec = gather_one_colspec(text)
	end
	text:expect("%s*%)%s*", "missing close parenthesis after colspecs")
	return specs
end
local color
color = function(text, ground)
	local spec = nil
	if text:scan(tostring(ground) .. "%(") then
		spec = known_color(text)
		if not spec then
			spec = expect(any_color, text, "expecting color")
		end
		text:expect("%)", "expected a single-word color name followed by a ')' ")
	end
	if spec then
		text:skip("%s*")
		spec.type = ground
	end
	return spec
end
local bg
bg = function(text)
	local spec = color(text, "bg") or known_color(text)
	if spec then
		spec.type = "bg"
	end
	return spec
end
local fg
fg = function(text)
	return color(text, "fg")
end
local footer
footer = function(text)
	if text:scan("footer%f[%A]") or text:scan("foot%f[%A]") then
		return {
			type = "footer"
		}
	end
end
local header
header = function(text)
	if text:scan("header%f[%A]") or text:scan("head%f[%A]") then
		return {
			type = "header"
		}
	end
end
local hlines
hlines = function(text)
	if text:scan("hlines%f[%A]") then
		return {
			type = "hlines"
		}
	end
end
local large
large = function(text)
	local match, xs = text:scan("(x*)large%f[%A]")
	if match then
		return {
			type = "large",
			amount = (function()
				if xs then
					return #xs
				else
					return 0
				end
			end)()
		}
	end
end
local lines
lines = function(text)
	local spec = nil
	if text:scan("lines?%(") then
		spec = expect(lines, text, "expecting line specifier, one or more of: t, b, l, r, x")
		text:expect("%)", "expected closing parenthesis after line specifier")
	else
		if text:scan("[tblrx]+") then
			spec = {
				type = "lines",
				spec = text.last_match
			}
		end
	end
	return spec
end
local normal
normal = function(text)
	if text:scan("normal%f[%A]") then
		return {
			type = "normal"
		}
	end
end
local small
small = function(text)
	local match, xs = text:scan("(x*)small%f[%A]")
	if match then
		return {
			type = "small",
			amount = (function()
				if xs then
					return #xs
				else
					return 0
				end
			end)()
		}
	end
end
local span
span = function(text)
	if text:scan("span%f[%A]%s*") then
		return {
			type = "span"
		}
	end
end
local style
style = function(text)
	local spec = nil
	if text:scan("%.[%w_-]+") then
		spec = string.sub(text.last_match, 2)
		text:scan("%s*")
	end
	if spec then
		return {
			type = "style",
			spec = spec
		}
	end
end
local vlines
vlines = function(text)
	if text:scan("vlines%f[%A]") then
		return {
			type = "vlines"
		}
	end
end
local width
width = function(text)
	local spec = nil
	if text:scan("width%(") then
		spec = expect(width, text, "expecting an integer width")
		text:expect("%)", "expected closing parenthesis after width")
	else
		if text:scan("0?%.[1-9][0-9]*") or text:scan("[1-9][0-9]*") then
			local wid = tonumber(text.last_match)
			if text:scan("%%") then
				wid = wid / 100.0
			end
			spec = {
				type = "width",
				spec = wid
			}
		end
	end
	return spec
end
gather_one_colspec = function(text)
	local specs = { }
	local valid_specs
	valid_specs = function(text)
		return align(text) or width(text) or lines(text) or fg(text) or bg(text)
	end
	local spec = valid_specs(text)
	while spec do
		specs[#specs + 1] = spec
		text:skip("%s*")
		spec = valid_specs(text)
	end
	return specs
end
local parse_global_formats
parse_global_formats = function(text)
	return align(text) or bg(text) or boxed(text) or cols(text) or fg(text) or hlines(text) or large(text) or normal(text) or small(text) or style(text) or vlines(text) or width(text)
end
_module_0["parse_global_formats"] = parse_global_formats
local parse_selector_formats
parse_selector_formats = function(text)
	text:skip("%s+")
	if text:empty() then
		return
	end
	return align(text) or bg(text) or fg(text) or footer(text) or header(text) or large(text) or normal(text) or small(text) or span(text) or style(text) or width(text) or lines(text)
end
_module_0["parse_selector_formats"] = parse_selector_formats
return _module_0
