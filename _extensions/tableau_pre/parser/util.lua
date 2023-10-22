local _module_0 = { }
local trim
trim = function(str)
	return string.gsub(string.gsub(str, "^%s+", ""), "%s+$", "")
end
_module_0["trim"] = trim
local split
split = function(str, delim, maxNb)
	if delim == nil then
		delim = "%s+"
	end
	if maxNb == nil then
		maxNb = 0
	end
	if string.find(str, delim) == nil then
		return {
			str
		}
	end
	local result
	result = { }
	local epos
	epos = "cat"
	for substr, pos in string.gmatch(str, "(.-)" .. tostring(delim) .. "()") do
		epos = pos
		result[#result + 1] = substr
	end
	if epos < string.len(str) then
		result[#result + 1] = string.sub(str, epos)
	end
	return result
end
_module_0["split"] = split
local dump
dump = function(value, label)
	if label == nil then
		label = nil
	end
	if label then
		print("\nvvv " .. tostring(label))
	end
	print(value)
	if label then
		print("^^^\n")
	end
	return value
end
_module_0["dump"] = dump
local expect
expect = function(parse_step, text, msg)
	if msg == nil then
		msg = "Syntax error in table specification"
	end
	return parse_step(text) or dump(text)
end
_module_0["expect"] = expect
return _module_0
