local _module_0 = { }
local dump, expect
do
	local _obj_0 = require("parser.util")
	dump, expect = _obj_0.dump, _obj_0.expect
end
local range_of
range_of = function(range, rno)
	local n1 = range.n1({
		row = rno
	})
	local n2 = range.n2({
		row = rno
	})
	local skip = range.skip
	local current = n1 - 1
	return function(self)
		while current < n2 do
			current = current + 1
			if skip({
				absolute = current,
				relative = current - n1
			}) then
				return current
			end
		end
	end
end
local iterate_combination
iterate_combination = function(row, col, cb)
	for rno in range_of(row, nil) do
		for cno in range_of(col, rno) do
			cb(rno, cno)
		end
	end
end
local iterate_selector
iterate_selector = function(selector, cb)
	local rows = selector.row
	local cols = selector.col
	for r = 1, #rows do
		for c = 1, #cols do
			iterate_combination(rows[r], cols[c], cb)
		end
	end
end
local iterate_column
iterate_column = function(selector, cb)
	local cols = selector.col
	for c = 1, #cols do
		for cno in range_of(cols[c], nil) do
			cb(nil, cno)
		end
	end
end
local iterate_selectors
iterate_selectors = function(selectors, cb)
	for i = 1, #selectors do
		iterate_selector(selectors[i], cb)
	end
end
_module_0["iterate_selectors"] = iterate_selectors
return _module_0
