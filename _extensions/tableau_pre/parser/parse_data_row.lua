local _module_0 = { }
local dump = require("parser.util").dump
local StringScanner = require("parser.string_scanner").StringScanner
local util = require("parser.util")
local FMT_MSG = "A table should contain two or more rows, each starting\nand ending with a pipe character (\"|\").\n"
local parse_fail
parse_fail = function(msg)
	io.stderr:write(msg)
	return false
end
local unknown_table_row
unknown_table_row = function(row_source)
	return parse_fail("Can't decipher table row: " .. tostring(row_source) .. "\n" .. tostring(FMT_MSG))
end
local cell_fragment
cell_fragment = function(row)
	return row:scan("`[^`]+`") or row:scan("$[^$]+%$") or row:scan("\\%|") or row:scan("[^`$|]+")
end
local cell_content
cell_content = function(row)
	local result = { }
	local fragment = cell_fragment(row)
	while fragment do
		result[#result + 1] = fragment
		fragment = cell_fragment(row)
	end
	if #result == 0 and row:looking_at("|") then
		result = {
			""
		}
	end
	return result
end
local pandoc = pandoc or {
	utils = {
		stringify = function(str)
			return str[1]
		end
	}
}
local cell
cell = function(row)
	row:skip("%s*|%s*")
	if row:looking_at("\n") then
		return false
	end
	if row:scan("=empty%s*$") then
		return {
			width = 0,
			content = {
				"&nbsp;"
			}
		}
	end
	local content = cell_content(row)
	if not content or #content == 0 then
		return false
	end
	local str
	str = pandoc.utils.stringify(content)
	local width
	if str and str ~= "" then
		width = string.len(str)
	else
		width = 1
	end
	return {
		width = width,
		content = content
	}
end
local content_row
content_row = function(row)
	local result = { }
	local a_cell = cell(row)
	while a_cell do
		result[#result + 1] = a_cell
		a_cell = cell(row)
	end
	if #result == 0 then
		return {
			{
				width = 0,
				content = {
					""
				}
			}
		}
	else
		return result
	end
end
local parse_data_row
parse_data_row = function(row_source)
	local row = StringScanner(util.trim(row_source))
	return content_row(row) or unknown_table_row(row:peek(100))
end
_module_0["parse_data_row"] = parse_data_row
return _module_0
