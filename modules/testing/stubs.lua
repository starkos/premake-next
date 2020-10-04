---
-- Stub out problematic Lua functions while tests are running.
---

local testing = select(1, ...)


local function stub()
end


testing.onBeforeTest(function()
	test.print = print
	print = stub
end)


testing.onAfterTest(function()
	print = test.print
end)
