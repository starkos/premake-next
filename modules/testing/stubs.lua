---
-- Stub out problematic Lua functions while tests are running.
---

local test = select(1, ...)


local function stub()
end


test.onBeforeTest(function()
	test.print = print
	print = stub
end)


test.onAfterTest(function()
	print = test.print
end)
