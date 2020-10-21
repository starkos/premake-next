local TableJoinArrayTests = test.declare('TableJoinArrayTests', 'table')


---
-- `joinArrays()` should append new array values to the end of the previous array.
---

function TableJoinArrayTests.joinArrays_appendsNewArrayValues_onEmptyPreviousArray()
	local result = table.joinArrays({}, { 'aeryn', 'john' })
	test.isEqual({ 'aeryn', 'john' }, result)
end

function TableJoinArrayTests.joinArrays_appendsNewArrayValues_onPreviousArray()
	local result = table.joinArrays({ 'aeryn', 'john' }, { 'rigel', 'pilot' })
	test.isEqual({ 'aeryn', 'john', 'rigel', 'pilot' }, result)
end

function TableJoinArrayTests.joinArrays_appendsSimpleValues_onOldArray()
	local result = table.joinArrays({ 'aeryn', 'john' }, 'rigel', 'pilot')
	test.isEqual({ 'aeryn', 'john', 'rigel', 'pilot' }, result)
end

function TableJoinArrayTests.joinArrays_appendsSimpleValues()
	local result = table.joinArrays('aeryn', 'john', 'rigel', 'pilot')
	test.isEqual({ 'aeryn', 'john', 'rigel', 'pilot' }, result)
end
