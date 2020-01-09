---
-- Premake helper APIs.
---

local buffer = require('buffer')

local m = _PREMAKE.premake

_PREMAKE.VERSION = '6.0.0-next'
_PREMAKE.COPYRIGHT = 'Copyright (C) 2002-2020 Jason Perkins and the Premake Project'
_PREMAKE.WEBSITE = 'https://github.com/starkos/premake-next'


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


local _captured

function m.capture(fn)
	local previousCapture = _captured

	_captured = buffer.new()
	fn()
	local captured = buffer.close(_captured)

	_captured = previousCapture
	return captured
end


function m.captured()
	if _captured then
		return buffer.tostring(_captured)
	else
		return ''
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


local _eol

function m.eol(newValue)
	_eol = newValue or _eol
	return _eol
end


return m
