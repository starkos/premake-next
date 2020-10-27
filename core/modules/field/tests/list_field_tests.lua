local Field = require('field')

local ListFieldTests = test.declare('ListFieldTests', 'field')


local testField

function ListFieldTests.setup()
	testField = Field.register({
		name = 'testField',
		kind = 'list:string'
	})
end

function ListFieldTests.teardown()
	Field.remove(testField)
end


---
-- `default()`
---

function ListFieldTests.default_isEmptyList()
	test.isEqual({}, testField:defaultValue())
end

---
-- matches()
---

function ListFieldTests.matches_isTrue_onMatch()
	test.isTrue(testField:matches({ 'x', 'y' }, 'x'))
end

function ListFieldTests.matches_isFalse_onMismatch()
	test.isFalse(testField:matches({ 'x', 'y' }, 'z'))
end

function ListFieldTests.matches_isFalse_onEmptyList()
	test.isFalse(testField:matches({}, 'z'))
end


---
-- `mergeValues()` should replace simple values, or append to collections.
---

function ListFieldTests.mergeValues_addsValue_onNilCollection()
	local newValue = testField:mergeValues(nil, 'a')
	test.isEqual({ 'a' }, newValue)
end

function ListFieldTests.mergeValues_addsValue_onEmptyCollection()
	local newValue = testField:mergeValues({}, 'a')
	test.isEqual({ 'a' }, newValue)
end

function ListFieldTests.mergeValues_addsValue_onExistingCollection()
	local newValue = testField:mergeValues({ 'a', 'b' }, 'c')
	test.isEqual({ 'a', 'b', 'c' }, newValue)
end


---
-- `removeValues()`
---

function ListFieldTests.removeValues_removes_onMatchingValue()
	local value = testField:removeValues({ 'x', 'y', 'z' }, { 'y' })
	test.isEqual({ 'x', 'z' }, value)
end

function ListFieldTests.removeValues_removes_onMultipleMatchingValue()
	local value = testField:removeValues({ 'u', 'v', 'w', 'x', 'y', 'z' }, { 'v', 'w', 'y' })
	test.isEqual({ 'u', 'x', 'z' }, value)
end

function ListFieldTests.removeValues_doesNothing_onMismatch()
	local value = testField:removeValues({ 'x', 'y', 'z' }, { 'a' })
	test.isEqual({ 'x', 'y', 'z' }, value)
end
