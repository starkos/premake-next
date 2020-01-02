---
-- File system path handling functions.
---

local m = _PREMAKE.path


function m.getBaseName(self)
	local name = m.getName(self)
	local i = string.findLast(self, '.', true)
	if i then
		return string.sub(name, 1, i - 1)
	else
		return name
	end
end


function m.getName(self)
	local i = string.findLast(self, "[/\\]")
	if i then
		return string.sub(self, i + 1)
	else
		return self
	end
end


return m
