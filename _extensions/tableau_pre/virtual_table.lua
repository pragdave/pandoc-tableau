local _module_0 = { }
local dump = require("parser.util").dump
local iterate_colspecs, iterate_selectors
do
	local _obj_0 = require("iterate_selector")
	iterate_colspecs, iterate_selectors = _obj_0.iterate_colspecs, _obj_0.iterate_selectors
end
local Cell
local normalize_colspecs
normalize_colspecs = function(colspecs)
	local width = 0
	for i = 1, #colspecs do
		width = width + colspecs[i][2]
	end
	if width < 60 then
		for i = 1, #colspecs do
			colspecs[i][2] = "ColWidthDefault"
		end
		return colspecs
	end
	if #colspecs <= 5 then
		local min_width = width / 10.0
		width = 0
		for i = 1, #colspecs do
			colspecs[i][2] = math.max(min_width, colspecs[i][2])
			width = width + colspecs[i][2]
		end
	end
	for i = 1, #colspecs do
		colspecs[i][2] = colspecs[i][2] / width
	end
	return colspecs
end
local most_common_alignment
most_common_alignment = function(rows)
	local result
	do
		local _tbl_0 = { }
		for i = 1, #rows[1] do
			local _key_0, _val_0 = "c"
			_tbl_0[_key_0] = _val_0
		end
		result = _tbl_0
	end
	return result
end
local remove_colspec_alignments_from
remove_colspec_alignments_from = function(self, rows, alignments)
	return nil
end
local column_widths
column_widths = function(rows)
	local row_count = #rows
	local col_count = #rows[1]
	local percent_widths = { }
	local absolute_widths = { }
	for c = 1, col_count do
		percent_widths[c] = 0
		absolute_widths[c] = 0
		for r = 1, row_count do
			local cell = rows[r][c]
			local width = cell:calculated_width()
			if width and width ~= "ColWidthDefault" then
				if width < 1 then
					if percent_widths[c] < width then
						percent_widths[c] = width
					end
				else
					if absolute_widths[c] < width then
						absolute_widths[c] = width
					end
				end
			end
		end
	end
	local total_absolute = 0
	local total_percent = 0
	for c = 1, col_count do
		if percent_widths[c] > 0 then
			total_percent = total_percent + percent_widths[c]
		else
			total_absolute = total_absolute + absolute_widths[c]
		end
	end
	if total_absolute > 0 then
		local space_left = 1 - total_percent
		for c = 1, col_count do
			if absolute_widths[c] > 0 then
				percent_widths[c] = absolute_widths[c] / total_absolute * space_left
			end
		end
	end
	return percent_widths
end
local derive_colspecs
derive_colspecs = function(rows)
	local col_count = #rows[1]
	local alignments = most_common_alignment(rows)
	remove_colspec_alignments_from(rows, alignments)
	local widths = column_widths(rows)
	local result
	do
		local _accum_0 = { }
		local _len_0 = 1
		for i = 1, col_count do
			_accum_0[_len_0] = {
				alignments[i],
				widths[i]
			}
			_len_0 = _len_0 + 1
		end
		result = _accum_0
	end
	return result
end
local split_align
split_align = function(spec)
	return spec:match("[lcrj]"), spec:match("[tmb]")
end
local convert_cell
convert_cell = function(cell)
	return Cell((function()
		if cell then
			return cell.content
		else
			return {
				""
			}
		end
	end)())
end
local convert_row
convert_row = function(row, col_count)
	local _accum_0 = { }
	local _len_0 = 1
	for col = 1, col_count do
		_accum_0[_len_0] = convert_cell(row[col])
		_len_0 = _len_0 + 1
	end
	return _accum_0
end
local adjust_to_max
adjust_to_max = function(current_max, row)
	for i = 1, #row do
		local current_width = current_max[i][2]
		local incoming_width = row[i].width
		if incoming_width > current_width then
			current_max[i][2] = incoming_width
		end
	end
end
local add_line_classes
add_line_classes = function(cell, spec)
	for i = 1, spec:len() do
		local side = spec:sub(i, i)
		cell:add_style("line-" .. tostring(side))
	end
end
local xs
xs = function(amount)
	if x > 0 then
		return string.rep("x", amount)
	end
end
local extract_styles
extract_styles = function(selector_no, style_list, cell)
	for _index_0 = 1, #style_list do
		local format = style_list[_index_0]
		do
			local _exp_0 = format.type
			if "style" == _exp_0 then
				cell:add_style(format.spec)
			elseif "bg" == _exp_0 then
				cell:set_bg(format)
			elseif "fg" == _exp_0 then
				cell:set_fg(format)
			elseif "align" == _exp_0 then
				local h, v = split_align(format.spec)
				cell:set_align(h, v)
			elseif "header" == _exp_0 then
				cell:add_style("tableau-th")
			elseif "footer" == _exp_0 then
				cell:add_style("tableau-tf")
			elseif "large" == _exp_0 or "small" == _exp_0 then
				cell:set_font_size(format.type, format.amount)
			elseif "normal" == _exp_0 then
				cell:set_font_size("medium", 0)
			elseif "lines" == _exp_0 then
				add_line_classes(cell, format.spec)
			elseif "span" == _exp_0 then
				cell:add_span(selector_no)
			elseif "width" == _exp_0 then
				cell:set_width(format.spec)
			else
				error("Unsupported global table option: " .. tostring(format.type))
			end
		end
	end
end
do
	local _class_0
	local _base_0 = {
		merge_styles = function(self, selector_no, styles)
			return extract_styles(selector_no, styles, self)
		end,
		calculated_width = function(self)
			return self.width or self:text_width()
		end,
		text_width = function(self)
			return 20
		end,
		add_style = function(self, style)
			do
				local _obj_0 = self.styles
				_obj_0[#_obj_0 + 1] = style
			end
		end,
		add_span = function(self, selector_no)
			self.span_group = selector_no
		end,
		set_fg = function(self, color)
			self.fg = color
		end,
		set_bg = function(self, color)
			self.bg = color
		end,
		set_align = function(self, h, v)
			if h then
				self.h_align = h
			end
			if v then
				self.v_align = v
			end
		end,
		set_font_size = function(self, size, amount)
			self.font_size = {
				type = size,
				amount = amount
			}
		end,
		set_width = function(self, width)
			self.width = width
		end
	}
	if _base_0.__index == nil then
		_base_0.__index = _base_0
	end
	_class_0 = setmetatable({
		__init = function(self, content)
			self.content = content
			self.styles = { }
			self.font_size = nil
			self.width = nil
		end,
		__base = _base_0,
		__name = "Cell"
	}, {
		__index = _base_0,
		__call = function(cls, ...)
			local _self_0 = setmetatable({ }, _base_0)
			cls.__init(_self_0, ...)
			return _self_0
		end
	})
	_base_0.__class = _class_0
	Cell = _class_0
end
local VirtualTable
do
	local _class_0
	local _base_0 = {
		import_content = function(self, ast)
			self:import_global_options(ast)
			self.table, self.colspecs = self:setup_rows_and_columns(ast)
			self:merge_table_level_options_into_cells()
			self:merge_styles_from_selectors(ast)
			self.colspecs = derive_colspecs(self.table)
		end,
		import_global_options = function(self, ast)
			for k, v in pairs(ast.table_flags) do
				if v then
					do
						local _obj_0 = self.styles
						_obj_0[#_obj_0 + 1] = "tbl-" .. tostring(k)
					end
				end
			end
			return extract_styles(0, ast.table_formats, self)
		end,
		setup_rows_and_columns = function(self, ast)
			local table = { }
			local colspecs
			do
				local _accum_0 = { }
				local _len_0 = 1
				for i = 1, ast.col_count do
					_accum_0[_len_0] = {
						"c",
						1
					}
					_len_0 = _len_0 + 1
				end
				colspecs = _accum_0
			end
			local _list_0 = ast.rows
			for _index_0 = 1, #_list_0 do
				local row = _list_0[_index_0]
				table[#table + 1] = convert_row(row, ast.col_count)
				adjust_to_max(colspecs, row)
			end
			colspecs = normalize_colspecs(colspecs)
			return table, colspecs
		end,
		merge_table_level_options_into_cells = function(self)
			local _list_0 = self.table
			for _index_0 = 1, #_list_0 do
				local row = _list_0[_index_0]
				for col = 1, #row do
					local cell
					cell = row[col]
					cell:set_align(self.h_align, self.v_align)
					if self.font_size then
						cell:add_style(self.font_size)
					end
					if self.font_size_amount then
						cell:add_style(self.font_size_amount)
					end
					if self.fg then
						cell:set_fg(self.fg)
					end
					if self.bg then
						cell:set_bg(self.bg)
					end
					cell:set_width(self.colspecs[col][2])
				end
			end
		end,
		merge_styles_from_selectors = function(self, ast)
			for selector_no, _des_0 in pairs(ast.selector_formats) do
				local selector, formats = _des_0.selector, _des_0.formats
				iterate_selectors(selector, function(row, col)
					if row >= 1 and row <= ast.row_count then
						if col >= 1 and col <= ast.col_count then
							return self.table[row][col]:merge_styles(selector_no, formats)
						end
					end
				end)
			end
		end,
		add_style = function(self, style)
			do
				local _obj_0 = self.styles
				_obj_0[#_obj_0 + 1] = style
			end
		end,
		set_fg = function(self, color)
			self.fg = color
		end,
		set_bg = function(self, color)
			self.bg = color
		end,
		set_align = function(self, h, v)
			self.h_align = h
			self.v_align = v
		end,
		set_font_size = function(self, size, amount)
			self.font_size = "tableau-" .. tostring(size)
			if amount > 0 then
				self.font_size_amount = string.rep("x", amount)
			end
		end,
		set_width = function(self, width)
			self.width = width
		end
	}
	if _base_0.__index == nil then
		_base_0.__index = _base_0
	end
	_class_0 = setmetatable({
		__init = function(self, ast)
			self.styles = { }
			self.caption = ast.caption
			return self:import_content(ast)
		end,
		__base = _base_0,
		__name = "VirtualTable"
	}, {
		__index = _base_0,
		__call = function(cls, ...)
			local _self_0 = setmetatable({ }, _base_0)
			cls.__init(_self_0, ...)
			return _self_0
		end
	})
	_base_0.__class = _class_0
	VirtualTable = _class_0
end
_module_0["VirtualTable"] = VirtualTable
return _module_0
