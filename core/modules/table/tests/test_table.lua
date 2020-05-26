local table = require('table')

local TableTests = test.declare('table')


---
-- `contains()` should correctly determine if the value exists.
---

function TableTests.contains_isTrue_onValueIsPresent()
	test.isTrue(table.contains({ 'one', 'two', 'three' }, 'two'))
end

function TableTests.contains_isFalse_onValueNotPresent()
	test.isFalse( table.contains({ 'one', 'two', 'three' }, 'four') )
end


---
-- `forEach()` should call the function once for each item in the array.
---

function TableTests.forEach_callsOncePerElement()
	local result = {}
	table.forEach({ 'one', 'two', 'three'}, function(value)
		table.insert(result, value)
	end)
	test.isEqual({ 'one', 'two', 'three' }, result)
end


---
-- `joinArrays()` should append new array values to the end of the previous array.
---

function TableTests.joinArrays_appendsNewArrayValues_onEmptyPreviousArray()
	local result = table.joinArrays({}, { 'aeryn', 'john' })
	test.isEqual({ 'aeryn', 'john' }, result)
end

function TableTests.joinArrays_appendsNewArrayValues_onPreviousArray()
	local result = table.joinArrays({ 'aeryn', 'john' }, { 'rigel', 'pilot' })
	test.isEqual({ 'aeryn', 'john', 'rigel', 'pilot' }, result)
end

function TableTests.joinArrays_appendsSimpleValues_onOldArray()
	local result = table.joinArrays({ 'aeryn', 'john' }, 'rigel', 'pilot')
	test.isEqual({ 'aeryn', 'john', 'rigel', 'pilot' }, result)
end

function TableTests.joinArrays_appendsSimpleValues()
	local result = table.joinArrays('aeryn', 'john', 'rigel', 'pilot')
	test.isEqual({ 'aeryn', 'john', 'rigel', 'pilot' }, result)
end


---
-- `map()` should call the provided function for each key.
---

function TableTests.map_callsFuncOnEachKey()
	local result = table.map({ 'A', 'B', 'C'}, function(key, value)
		return value .. 'x'
	end)
	test.isEqual({ 'Ax', 'Bx', 'Cx' }, result)
end
