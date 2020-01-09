---
-- Stub out problematic Lua functions while tests are running.
---

local m = select(1, ...)

local _print


local function stub_print()
end


m.onBeforeTest(function()
	_print = print
	print = stub_print
end)


m.onAfterTest(function()
	print = _print
end)
