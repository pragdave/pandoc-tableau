local _module_0 = { }
local parse_selector = require("parser.parse_selector").parse_selector
local parse_selector_formats, parse_global_formats
do
	local _obj_0 = require("parser.parse_formats")
	parse_selector_formats, parse_global_formats = _obj_0.parse_selector_formats, _obj_0.parse_global_formats
end
local StringScanner = require("parser.string_scanner").StringScanner
local util = require("parser.util")
local expect, dump
do
	local _obj_0 = require("parser.util")
	expect, dump = _obj_0.expect, _obj_0.dump
end
local FMT_MSG = [[A format line can be:

  * blank
  * -- a command
  * # caption or :caption
  * selector = format
  * global_format

]]
local parse_error
parse_error = function(row)
	return row:parse_error(FMT_MSG)
end
local formats_list
formats_list = function(parser, row)
	local format = expect(parser, row, "missing a format after 'selector ='")
	local result = { }
	while format do
		result[#result + 1] = format
		row:skip("%s*,")
		row:skip("%s*")
		format = parser(row)
	end
	return result
end
local blank_or_comment
blank_or_comment = function(row)
	if row:scan("%s*%-%-") or row:scan("%s*$") then
		return {
			type = "blank"
		}
	end
end
local caption
caption = function(row)
	if row:skip("#+%s+") or row:skip(":%s+") then
		if row:empty() then
			return {
				type = "error",
				msg = "missing text for caption"
			}
		else
			return {
				type = "caption",
				caption = row:scan(".*")
			}
		end
	end
end
local selected
selected = function(ast, row)
	local selector = parse_selector(ast, row)
	if not selector then
		return
	end
	row:expect("%s*=%s*", "expected equals sign between selector and attributes")
	local formats = formats_list(parse_selector_formats, row)
	row:expect("%s*$", "extra stuff after last attribute")
	return {
		type = "selector",
		selector = selector,
		formats = formats
	}
end
local globl
globl = function(row)
	local formats = formats_list(parse_global_formats, row)
	row:expect("%s*$", "extra stuff after last attribute")
	return {
		type = "global",
		formats = formats
	}
end
local parse_layout_row
parse_layout_row = function(ast, row_source)
	local row = StringScanner(util.trim(row_source))
	local result = blank_or_comment(row) or caption(row) or selected(ast, row) or globl(row) or parse_error(row)
	return result
end
_module_0["parse_layout_row"] = parse_layout_row
return _module_0
