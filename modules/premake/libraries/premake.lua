---
-- Miscellaneous Premake-specific helper functions.
---

local m = select(1, ...)

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
