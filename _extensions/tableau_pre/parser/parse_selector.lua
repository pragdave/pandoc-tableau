local _module_0 = { }
local StringScanner = require("parser.string_scanner").StringScanner
local dump, expect
do
	local _obj_0 = require("parser.util")
	dump, expect = _obj_0.dump, _obj_0.expect
end
local integer
integer = function(state)
	local num = state.input:scan("[1-9][0-9]*")
	if num then
		return {
			type = 'integer',
			value = tonumber(num)
		}
	end
end
local adjustment
adjustment = function(state)
	local sign = state.input:scan("[~+]")
	if not sign then
		return
	end
	local offset = expect(integer, state, "number expected after +/-")
	if sign == "~" then
		return function(n)
			return n - offset.value
		end
	else
		return function(n)
			return n + offset.value
		end
	end
end
local ast_value_constant
ast_value_constant = function(val)
	return function(_)
		return val
	end
end
local value
value = function(state)
	if state.input:scan('%$r') then
		return ast_value_constant(state.ast.row_count)
	elseif state.input:scan('%$c') then
		return ast_value_constant(state.ast.col_count)
	elseif state.input:scan('@r') then
		return function(pos)
			return pos.row
		end
	elseif state.input:scan('@c') then
		return state.input:parse_error("Sorry, '@c' can't be supported, because the row is evaluated before the column")
	else
		local s = integer(state)
		if s then
			return function(_)
				return s.value
			end
		end
	end
end
local n
n = function(state)
	local val = value(state)
	if not val then
		return
	end
	local adjust_fn = adjustment(state)
	if adjust_fn then
		return function(param)
			return adjust_fn(val(param))
		end
	else
		return val
	end
end
local expect_skip
expect_skip = function(state)
	if state.input:scan('odd%f[^%a]') then
		return function(n)
			return n % 2 == 1
		end
	elseif state.input:scan('even%f[^%a]') then
		return function(n)
			return n % 2 == 0
		end
	else
		local s = expect(integer, state, "expected 'odd', 'even', or a number as a skip value")
		return function(n)
			return (n % s.value) == 0
		end
	end
end
local complex_selector
complex_selector = function(state, max)
	local n1 = n(state)
	local n2 = nil
	local skip
	skip = function(self, _pos)
		return true
	end
	if n1 then
		if state.input:skip("-") then
			n2 = expect(n, state, 'second number expected after "-"')
			if state.input:skip("/") then
				local s = expect_skip(state)
				skip = function(pos)
					return s(pos.absolute)
				end
			elseif state.input:skip("\\") then
				local s = expect_skip(state)
				skip = function(pos)
					return s(pos.relative)
				end
			end
		end
	else
		n1 = ast_value_constant(1)
		n2 = ast_value_constant(max)
	end
	return {
		n1 = n1,
		n2 = n2 or n1,
		skip = skip
	}
end
local complex_selectors
complex_selectors = function(state, max)
	local result = { }
	local nxt = complex_selector(state, max)
	while nxt do
		result[#result + 1] = nxt
		nxt = nil
		if state.input:skip("%s*,%s*") then
			nxt = complex_selector(state, max)
		end
	end
	if #result > 0 then
		return result
	end
end
local col_or_row
col_or_row = function(state, flag_char, type, max)
	if not state.input:skip(flag_char) then
		return
	end
	return complex_selectors(state, max)
end
local col_selector
col_selector = function(state)
	return col_or_row(state, "c", "col_selector", state.ast.col_count)
end
local row_selector
row_selector = function(state)
	return col_or_row(state, "r", "row_selector", state.ast.row_count)
end
local term
term = function(state)
	local r = nil
	local c = nil
	r = row_selector(state)
	if r then
		if state.input:skip(":") then
			c = col_selector(state)
		end
	else
		c = col_selector(state)
	end
	if not r then
		r = {
			{
				n1 = ast_value_constant(1),
				n2 = ast_value_constant(state.ast.row_count),
				skip = function(_)
					return true
				end,
				defaulted = true
			}
		}
	end
	if not c then
		c = {
			{
				n1 = ast_value_constant(1),
				n2 = ast_value_constant(state.ast.col_count),
				skip = function(_)
					return true
				end
			}
		}
	end
	return {
		row = r,
		col = c
	}
end
local selector
selector = function(state)
	local sel = { }
	repeat
		sel[#sel + 1] = term(state)
	until not state.input:skip("%s*;%s*")
	return sel
end
local parse_selector
parse_selector = function(ast, scanner)
	if not scanner:looking_at("%s*[rc]") then
		return
	end
	local state = {
		input = scanner,
		ast = ast
	}
	state.input:skipws()
	if state.input:empty() then
		return entries
	end
	return selector(state)
end
_module_0["parse_selector"] = parse_selector
local parse_selector_from_string
parse_selector_from_string = function(ast, str)
	return parse_selector(ast, StringScanner(str))
end
_module_0["parse_selector_from_string"] = parse_selector_from_string
return _module_0
