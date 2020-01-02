---
-- The main Premake module.
--
-- Bootstraps the core APIs used by the rest of the application, and implements
-- the program entry point and overall execution flow.
---

local m = _PREMAKE.premake

_PREMAKE.VERSION = '6.0.0-next'
_PREMAKE.COPYRIGHT = 'Copyright (C) 2002-2020 Jason Perkins and the Premake Project'
_PREMAKE.WEBSITE = 'https://github.com/starkos/premake-next'


-- load extensions to Lua
doFile('_G.lua')
doFile('string.lua')


---
-- Call a list of functions.
--
-- @param funcs
--    The array of functions to be called, or a function that can be called
--    to build and return the list. If this is a function, it will be called
--    with the provided optional arguments (below).
-- @param ...
--    An optional set of arguments to be passed to each of the functions as
--    as they are called.
---
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


return m
