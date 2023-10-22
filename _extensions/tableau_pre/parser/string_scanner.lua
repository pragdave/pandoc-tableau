local _module_0 = { }
local util = require("parser.util")
local StringScanner
do
	local _class_0
	local _base_0 = {
		skip = function(self, pattern)
			local s, e = self.str:find("^" .. pattern, self.pos)
			if e then
				self.pos = e + 1
			end
			return e
		end,
		skipws = function(self)
			return self:skip("%s*")
		end,
		scan = function(self, pattern)
			local s, e, c1, c2, c3 = self.str:find("^" .. pattern, self.pos)
			if not e then
				return nil
			end
			if e then
				self.pos = e + 1
			end
			self.last_match = self.str:sub(s, e)
			return self.last_match, c1, c2, c3
		end,
		expect = function(self, pattern, msg)
			return self:scan(pattern) or self:parse_error(msg)
		end,
		looking_at = function(self, pattern)
			local s, e = self.str:find("^" .. pattern, self.pos)
			return not not e
		end,
		peek = function(self, len)
			return self.str:sub(self.pos, self.pos + len)
		end,
		empty = function(self)
			return self.pos > #self.str
		end,
		save_place = function(self)
			do
				local _obj_0 = self.pos_stack
				_obj_0[#_obj_0 + 1] = self.pos
			end
		end,
		restore_place = function(self)
			self.pos = table.remove(self.pos_stack)
		end,
		parse_error = function(self, msg)
			local err = {
				"\nTableau: " .. tostring(msg) .. "\n" .. tostring(self:state()) .. "\n"
			}
			for level = 4, 2, -1 do
				local f = debug.getinfo(level)
				err[#err + 1] = tostring(f.source) .. ": " .. tostring(f.currentline) .. " " .. tostring(f.name)
			end
			return error(table.concat(err, "\n"))
		end,
		state = function(self)
			return tostring(self.str:sub(1, self.pos - 1)) .. " «" .. tostring(self.str:sub(self.pos, self.pos)) .. "» " .. tostring(self.str:sub(self.pos + 1))
		end
	}
	if _base_0.__index == nil then
		_base_0.__index = _base_0
	end
	_class_0 = setmetatable({
		__init = function(self, str)
			self.str = str
			self.pos = 1
			self.pos_stack = { }
			self.last_match = nil
		end,
		__base = _base_0,
		__name = "StringScanner"
	}, {
		__index = _base_0,
		__call = function(cls, ...)
			local _self_0 = setmetatable({ }, _base_0)
			cls.__init(_self_0, ...)
			return _self_0
		end
	})
	_base_0.__class = _class_0
	StringScanner = _class_0
end
_module_0["StringScanner"] = StringScanner
return _module_0
