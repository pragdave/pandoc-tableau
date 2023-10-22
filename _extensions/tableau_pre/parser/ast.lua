local _module_0 = { }
local util = require("parser.util")
local parse_data_row = require("parser.parse_data_row").parse_data_row
local parse_layout_row = require("parser.parse_layout_row").parse_layout_row
if not re then
	re = require("re")
end
local LINE_CONTINUATION <const> = "\\\n"
local NEWLINE_PATTERN <const> = "\r?\n"
local dump = util.dump
local Ast
do
	local _class_0
	local _base_0 = {
		add_row = function(self, row)
			do
				local _obj_0 = self.rows
				_obj_0[#_obj_0 + 1] = row
			end
			self.row_count = self.row_count + 1
			self.col_count = math.max(self.col_count, #row)
		end,
		add_layout = function(self, layout)
			local _exp_0 = layout.type
			if "blank" == _exp_0 then
				return nil
			elseif "caption" == _exp_0 then
				self.caption = layout.caption
			elseif "selector" == _exp_0 then
				do
					local _obj_0 = self.selector_formats
					_obj_0[#_obj_0 + 1] = {
						selector = layout.selector,
						formats = layout.formats
					}
				end
			elseif "global" == _exp_0 then
				return self:add_global_formats(layout.formats)
			else
				return error("unknown layout type: " .. tostring(layout.type))
			end
		end,
		add_global_formats = function(self, formats)
			for _index_0 = 1, #formats do
				local fmt = formats[_index_0]
				do
					local _exp_0 = fmt.type
					if "boxed" == _exp_0 or "hlines" == _exp_0 or "vlines" == _exp_0 then
						self.table_flags[fmt.type] = true
					elseif "small" == _exp_0 or "normal" == _exp_0 or "large" == _exp_0 then
						self.table_font_size = tmp
					elseif "fg" == _exp_0 or "bg" == _exp_0 or "align" == _exp_0 or "style" == _exp_0 or "width" == _exp_0 then
						do
							local _obj_0 = self.table_formats
							_obj_0[#_obj_0 + 1] = fmt
						end
					elseif "cols" == _exp_0 then
						self.colspecs = fmt.colspec
					else
						io.stderr:write("Unknown table-level option: " .. tostring(fmt.type))
					end
				end
			end
		end
	}
	if _base_0.__index == nil then
		_base_0.__index = _base_0
	end
	_class_0 = setmetatable({
		__init = function(self)
			self.row_count = 0
			self.col_count = 0
			self.rows = { }
			self.caption = nil
			self.colspecs = { }
			self.selector_formats = { }
			self.table_formats = { }
			self.table_flags = { }
			self.font_size = {
				type = "normal",
				amount = 0
			}
		end,
		__base = _base_0,
		__name = "Ast"
	}, {
		__index = _base_0,
		__call = function(cls, ...)
			local _self_0 = setmetatable({ }, _base_0)
			cls.__init(_self_0, ...)
			return _self_0
		end
	})
	_base_0.__class = _class_0
	Ast = _class_0
end
local merge_continuation_lines
merge_continuation_lines = function(table)
	return table:gsub(LINE_CONTINUATION, "")
end
local split_into_rows
split_into_rows = function(table)
	return util.split(util.trim(table), NEWLINE_PATTERN)
end
local split_into_data_and_layout
split_into_data_and_layout = function(source)
	local data = source
	local layout = nil
	local s, e = source:find("\n%s*===%s*\n")
	if s then
		data = source:sub(1, s - 1)
		layout = source:sub(e + 1)
	end
	return {
		data,
		layout
	}
end
local decode_column_number
decode_column_number = function(c)
	if c:find("^%d+") then
		return tonumber(c)
	else
		return c:byte(1) - ("a"):byte(1) + 1
	end
end
local expandtabs
expandtabs = function(str, tabsize)
	if tabsize == nil then
		tabsize = 8
	end
	return str:gsub("([^\t\r\n]*)\t", function(before_tab)
		return before_tab .. (" "):rep(tabsize - #before_tab % tabsize)
	end)
end
local normalize
normalize = function(content)
	local spaces = 9999
	for i = 1, #content do
		content[i] = expandtabs(content[i])
		local _, e = content[i]:find("^%s*")
		spaces = math.min(spaces, e)
	end
	local _accum_0 = { }
	local _len_0 = 1
	for _index_0 = 1, #content do
		local r = content[_index_0]
		_accum_0[_len_0] = r:sub(spaces + 1)
		_len_0 = _len_0 + 1
	end
	return _accum_0
end
local col_text_re = re.compile([[  colheader <- prefix  [ \t]* {| colnumber |} [ \t]* '{{'
  prefix    <- 'column' / 'col'
  colnumber <- {:col: [1-9][0-9]?  / [a-z] :} 
]])
local merge_following_column_blocks
merge_following_column_blocks = function(rows, row_no, callback)
	while row_no <= #rows do
		local next = rows[row_no]:lower()
		local col = col_text_re:match(next)
		if not col then
			return row_no
		end
		local content = { }
		local col_no = decode_column_number(col.col)
		row_no = row_no + 1
		local r = rows[row_no]
		while not r:find("^%s*}}") and row_no < #rows do
			content[#content + 1] = r
			row_no = row_no + 1
			r = rows[row_no]
		end
		if row_no > #rows then
			error("Missing terminating '}}' for 'col " .. tostring(col_no) .. " {{'")
		end
		row_no = row_no + 1
		callback(col_no, normalize(content))
	end
	return row_no
end
local parse_data
parse_data = function(ast, data)
	local rows = split_into_rows(data)
	local row_no = 1
	while row_no <= #rows do
		local last_row = parse_data_row(rows[row_no])
		row_no = merge_following_column_blocks(rows, row_no + 1, function(col, content)
			if col <= #last_row then
				last_row[col].content = content
			end
		end)
		ast:add_row(last_row)
	end
end
local parse_layout
parse_layout = function(ast, layout)
	local rows = split_into_rows(layout)
	if #rows == 0 then
		return
	end
	for i = 1, #rows do
		layout = parse_layout_row(ast, rows[i])
		ast:add_layout(layout)
	end
end
local parse
parse = function(source)
	local data, layout
	do
		local _obj_0 = split_into_data_and_layout(merge_continuation_lines(source))
		data, layout = _obj_0[1], _obj_0[2]
	end
	local ast = Ast()
	parse_data(ast, data)
	if layout then
		parse_layout(ast, layout)
	end
	return ast
end
_module_0["parse"] = parse
return _module_0
