---
-- Premake helper APIs.
---

local m = _PREMAKE.premake

_PREMAKE.VERSION = '6.0.0-next'
_PREMAKE.COPYRIGHT = 'Copyright (C) 2002-2020 Jason Perkins and the Premake Project'
_PREMAKE.WEBSITE = 'https://github.com/starkos/premake-next'


doFile('_G.lua')
doFile('string.lua')


function m.callArray(funcs, ...)
	if type(funcs) == 'function' then
		funcs = funcs(...)
	end
	if funcs then
		for i = 1, #funcs do
			funcs[i](...)
		end
	end
end


function m.checkRequired(obj, ...)
	local n = select('#', ...)
	for i = 1, n do
		local field = select(i, ...)
		if not obj[field] then
			return false, string.format('missing required value `%s`', field)
		end
	end
	return true
end


return m
