local table = require('table')

local TableForEachTests = test.declare('TableForEachTests', 'table')


---
-- `forEach()` should call the function once for each item in the array.
---

function TableForEachTests.forEach_callsOncePerElement()
	local result = {}
	table.forEach({ 'one', 'two', 'three'}, function(value)
		table.insert(result, value)
	end)
	test.isEqual({ 'one', 'two', 'three' }, result)
end
