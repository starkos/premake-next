local Field = require('field')

local ListFieldTests = test.declare('ListFieldTests', 'field')


local testField

function ListFieldTests.setup()
	testField = Field.new({
		name = 'testField',
		kind = 'list:string'
	})
end

function ListFieldTests.teardown()
	Field.delete(testField)
end


---
-- `addValue()` should add to collections
---

function ListFieldTests.addValue_appendsToNilCollection()
	test.isEqual({ 'y' }, testField:mergeValues(nil, { 'y' }))
end

function ListFieldTests.addValue_appendsToExistingCollection()
	test.isEqual({ 'x', 'y' }, testField:mergeValues({ 'x' }, { 'y' }))
end


---
-- `removeValue()` should remove values from collections.
---

function ListFieldTests.removeValues_removes_onMatchingValue()
	test.isEqual({ 'x', 'z' }, testField:removeValues({ 'x', 'y', 'z' }, { 'y' }))
end


---
-- `canMatchPattern()` should return true if the provided pattern can be
-- matched against the field's value.
---

function ListFieldTests.contains_isTrue_onListValueMatch()
	test.isTrue(testField:contains({ 'x', 'y' }, 'x'))
end

function ListFieldTests.contains_isFalse_onListValueMismatch()
	test.isFalse(testField:contains({ 'x', 'y' }, 'z'))
end

function ListFieldTests.contains_isFalse_onPartialMatch()
	test.isFalse(testField:contains('partial', 'part'))
end
