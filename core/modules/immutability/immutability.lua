---
-- Do what we can to catch changes to objects which should be immutable.
---

local immutability = {}


local _MT = {
	__newindex = function (key, value)
		local msg = string.format('Attempted to add `%s` to immutable object', key)
		error(msg)
	end
}


function immutability.lock(object)
	return setmetatable(object, _MT)
end


function immutability.lockShallow(object)
	for key, value in pairs(object) do
		object[key] = setmetatable(value, _MT)
	end
end


return immutability
