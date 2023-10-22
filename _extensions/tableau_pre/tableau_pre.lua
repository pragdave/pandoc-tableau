local _module_0 = { }
local dump = require("./parser/util").dump
local parse = require("./parser/ast").parse
local VirtualTable = require("virtual_table").VirtualTable
if false then
	dump("just here to remove the 'unused' warning")
end
local append
append = table.insert
local md2ast
md2ast = function(str)
	return pandoc.read(str).blocks
end
local LINE_LEFT <const> = 1
local LINE_RIGHT <const> = 2
local LINE_TOP <const> = 4
local LINE_BOTTOM <const> = 8
local CellAttribute
do
	local _class_0
	local _base_0 = {
		merge = function(self, format_list)
			for _index_0 = 1, #format_list do
				local fmt = format_list[_index_0]
				do
					local _exp_0 = fmt.type
					if "width" == _exp_0 then
						self.width = fmt.spec
					elseif "lines" == _exp_0 then
						self.lines = self.lines | decode_lines(fmt.spec)
					else
						io.error:write("\n\nUnknown format " .. tostring(fmt.type) .. " ignored\n\n")
					end
				end
			end
		end
	}
	if _base_0.__index == nil then
		_base_0.__index = _base_0
	end
	_class_0 = setmetatable({
		__init = function(self, content)
			self.content = content
			self.width = nil
			self.fg = nil
			self.bg = nil
			self.align = nil
			self.lines = 0
			self.styles = { }
		end,
		__base = _base_0,
		__name = "CellAttribute"
	}, {
		__index = _base_0,
		__call = function(cls, ...)
			local _self_0 = setmetatable({ }, _base_0)
			cls.__init(_self_0, ...)
			return _self_0
		end
	})
	_base_0.__class = _class_0
	CellAttribute = _class_0
end
local extract_cells_and_attributes
extract_cells_and_attributes = function(table)
	local cells
	cells = function(row)
		local _accum_0 = { }
		local _len_0 = 1
		for _index_0 = 1, #row do
			local cells = row[_index_0]
			_accum_0[_len_0] = CellAttribute(cell.content)
			_len_0 = _len_0 + 1
		end
		return _accum_0
	end
	local _accum_0 = { }
	local _len_0 = 1
	for _index_0 = 1, #table do
		local row = table[_index_0]
		_accum_0[_len_0] = cells(row)
		_len_0 = _len_0 + 1
	end
	return _accum_0
end
local caption
caption = function(cap)
	if cap then
		return md2ast(cap)
	else
		return { }
	end
end
local alignment_for
alignment_for = function(spec)
	if "l" == spec then
		return "AlignLeft"
	elseif "r" == spec then
		return "AlignRight"
	else
		return "AlignCenter"
	end
end
local colspecs
colspecs = function(table)
	local specs = table.colspecs
	local _accum_0 = { }
	local _len_0 = 1
	for _index_0 = 1, #specs do
		local s = specs[_index_0]
		_accum_0[_len_0] = {
			alignment_for(s[1]),
			s[2]
		}
		_len_0 = _len_0 + 1
	end
	return _accum_0
end
local attr
attr = function(cell, id)
	local classes = { }
	local cell_attributes = { }
	local _list_0 = cell.styles
	for _index_0 = 1, #_list_0 do
		local cls = _list_0[_index_0]
		append(classes, cls)
	end
	if cell.fg then
		if cell.fg.color_type == "rgb" then
			cell_attributes["style"] = "color: " .. tostring(cell.fg.name)
		else
			classes[#classes + 1] = "fg-" .. tostring(cell.fg.name)
		end
	end
	if cell.bg then
		if cell.bg.color_type == "rgb" then
			cell_attributes["style"] = "background-color: " .. tostring(cell.bg.name)
		else
			classes[#classes + 1] = "bg-" .. tostring(cell.bg.name)
		end
	end
	local h_align = cell.h_align
	if h_align then
		classes[#classes + 1] = "align-h-" .. tostring(h_align)
	end
	local v_align = cell.v_align
	if v_align then
		classes[#classes + 1] = "align-v-" .. tostring(v_align)
	end
	if cell.font_size then
		local size = cell.font_size
		do
			local _exp_0 = size.type
			if "small" == _exp_0 or "large" == _exp_0 then
				classes[#classes + 1] = "tableau-" .. tostring(size.type)
				if size.amount > 0 then
					classes[#classes + 1] = "tableau-size-" .. tostring(string.rep('x', size.amount))
				end
			elseif "normal" == _exp_0 then
				classes[#classes + 1] = "medium"
			end
		end
	end
	return pandoc.Attr(id or "", classes, cell_attributes)
end
local cell_holder
cell_holder = function(cell)
	return pandoc.Cell(md2ast(table.concat(cell.content, "\n")), "AlignCenter", cell.row_span, cell.col_span, attr(cell, ""))
end
local maybe_add_hidden_cell
if quarto.doc.is_format("pdf") then
	maybe_add_hidden_cell = function(cells, c)
		return append(cells, cell_holder(c))
	end
else
	maybe_add_hidden_cell = function(cells, c)
		if not c.hidden_by_span then
			return append(cells, cell_holder(c))
		end
	end
end
local convert_row
convert_row = function(cells)
	local result
	result = { }
	for _index_0 = 1, #cells do
		local cell = cells[_index_0]
		maybe_add_hidden_cell(result, cell)
	end
	return pandoc.Row(result)
end
local convert_rows
convert_rows = function(table)
	local _accum_0 = { }
	local _len_0 = 1
	for _index_0 = 1, #table do
		local row_of_cells = table[_index_0]
		_accum_0[_len_0] = convert_row(row_of_cells)
		_len_0 = _len_0 + 1
	end
	return _accum_0
end
local find_and_mark_contiguous_block
find_and_mark_contiguous_block = function(body, r, c, group)
	local row_span = 0
	while (r + row_span) <= #body and body[r + row_span][c].span_group == group do
		row_span = row_span + 1
	end
	local max_col = #body[1]
	local col = c
	while col <= max_col and body[r][col].span_group == group do
		local row = r
		while row < (r + row_span) and body[row][col].span_group == group do
			row = row + 1
		end
		row_span = math.min(row_span, row - r + 1)
		col = col + 1
	end
	local col_span = col - c
	if row_span > 1 or col_span > 1 then
		for row = 0, row_span - 1 do
			for col = 0, col_span - 1 do
				body[r + row][c + col].span_group = nil
				body[r + row][c + col].hidden_by_span = true
			end
		end
		body[r][c].hidden_by_span = false
		if row_span > 1 then
			body[r][c].row_span = row_span
		end
		if col_span > 1 then
			body[r][c].col_span = col_span
		end
	end
end
local merge_spans
merge_spans = function(body)
	for r = 1, #body do
		local row
		row = body[r]
		for c = 1, #row do
			local cell = row[c]
			if cell.span_group then
				find_and_mark_contiguous_block(body, r, c, cell.span_group)
			end
		end
	end
end
local table_body
table_body = function(table)
	merge_spans(table)
	local body = convert_rows(table)
	return {
		head = { },
		body = convert_rows(table),
		row_head_columns = 0,
		attr = pandoc.Attr()
	}
end
local table_attr
table_attr = function(tbl, id)
	local classes
	classes = {
		"tableau-table"
	}
	local tbl_attributes
	tbl_attributes = { }
	local style
	style = { }
	local _list_0 = tbl.styles
	for _index_0 = 1, #_list_0 do
		local cls = _list_0[_index_0]
		append(classes, cls)
	end
	if tbl.fg then
		if tbl.fg.color_type == "rgb" then
			style[#style + 1] = "color: " .. tostring(tbl.fg.name)
		else
			classes[#classes + 1] = "fg-" .. tostring(tbl.fg.name)
		end
	end
	if tbl.bg then
		if tbl.bg.color_type == "rgb" then
			style[#style + 1] = "background-color: " .. tostring(tbl.bg.name)
		else
			classes[#classes + 1] = "bg-" .. tostring(tbl.bg.name)
		end
	end
	if tbl.width then
		local w = tbl.width
		if w < 1 then
			w = tostring(w * 100) .. "%"
		else
			w = tostring(w) .. "em"
		end
		style[#style + 1] = "width: " .. tostring(w)
	end
	return style, pandoc.Attr(id or "", classes, tbl_attributes)
end
local pandoc_table_from
pandoc_table_from = function(tbl, id)
	local rows = extract_cells_and_attributes(tbl)
	local style, attrs = table_attr(tbl, id)
	local result = pandoc.Table(caption(tbl.caption), colspecs(tbl), pandoc.TableHead({ }), {
		table_body(tbl.table)
	}, pandoc.TableFoot({ }), attrs)
	if style then
		if quarto.doc.is_format("html") then
			style = table.concat(style, "; ")
			result = {
				pandoc.RawBlock('html', "<div style=\"" .. tostring(style) .. "\">"),
				result,
				pandoc.RawBlock('html', '</div>')
			}
		end
	end
	return result
end
local CodeBlock
CodeBlock = function(block)
	if not (block.classes[1] == "tableau") then
		return
	end
	local ast = parse(block.text)
	if not ast then
		return
	end
	local table = VirtualTable(ast)
	return pandoc_table_from(table, block.attr.identifier)
end
_module_0["CodeBlock"] = CodeBlock
quarto.doc.add_html_dependency({
	name = "tableau",
	version = "1.0.0",
	stylesheets = {
		"assets/tableau.css"
	}
})
_module_0[#_module_0 + 1] = {
	CodeBlock = CodeBlock
}
return _module_0
