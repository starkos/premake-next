local Field = require('field')

local FieldTests = test.declare('FieldTests')


local stringField, listField

function FieldTests.setup()
	stringField = Field.new({
		name = 'stringField',
		kind = 'string'
	})

	listField = Field.new({
		name = 'listField',
		kind = 'list:string'
	})
end

function FieldTests.teardown()
	Field.delete(stringField)
	Field.delete(listField)
end


---
-- `register()` should return the populated field definition.
---

function FieldTests.register_returnsFieldDefinition()
	test.isNotNil(stringField)
end


---
-- `get()` with a valid field name should return the field's definition.
---

function FieldTests.get_returnsFieldDefinition()
	local result = Field.get('stringField')
	test.isNotNil(result)
end


---
-- `get` should raise an error if the field hasn't been registered.
---

function FieldTests.get_raisesError_onUnknownField()
	local ok, err = pcall(function()
		Field.get('no-such-field')
	end)

	test.isFalse(ok)
	test.isNotNil(err)
end


---
-- `exists` should return true for a valid field, and false otherwise.
---

function FieldTests.exists_returnsTrue_onValidField()
	test.isTrue(Field.exists('stringField'))
end

function FieldTests.exists_returnsFalse_onUnknownField()
	test.isFalse(Field.exists('no-such-field'))
end


---
-- `delete()` removes the field.
---

function FieldTests.delete_removesField_onValidField()
	Field.delete(stringField)
	test.isFalse(Field.exists('stringField'))
end


---
-- `addValue()` should replace simple values, or append to collections.
---

function FieldTests.addValue_setSimpleValue()
	local newValue = stringField:mergeValues(nil, 'newValue')
	test.isEqual('newValue', newValue)
end

function FieldTests.addValue_replacesSimpleValue()
	local newValue = stringField:mergeValues('x', 'y')
	test.isEqual('y', newValue)
end

function FieldTests.addValue_appendsToNilCollection()
	local newValue = listField:mergeValues(nil, { 'y' })
	test.isEqual({ 'y' }, newValue)
end

function FieldTests.addValue_appendsToExistingCollection()
	local newValue = listField:mergeValues({ 'x' }, { 'y' })
	test.isEqual({ 'x', 'y' }, newValue)
end


---
-- `removeValue()` should remove values from collections.
---

function FieldTests.removeValues_removes_onMatchingValue()
	local newValue = listField:removeValues({ 'x', 'y', 'z' }, { 'y' })
	test.isEqual({ 'x', 'z' }, newValue)
end


---
-- `canMatchPattern()` should return true if the provided pattern can be
-- matched against the field's value.
---

function FieldTests.contains_isTrue_onSimpleValueMatch()
	test.isTrue(stringField:contains('x', 'x'))
end

function FieldTests.contains_isFalse_onSimpleValueMismatch()
	test.isFalse(stringField:contains('x', 'y'))
end

function FieldTests.contains_isTrue_onListValueMatch()
	test.isTrue(listField:contains({ 'x', 'y' }, 'x'))
end

function FieldTests.contains_isFalse_onListValueMismatch()
	test.isFalse(listField:contains({ 'x', 'y' }, 'z'))
end

function FieldTests.contains_isFalse_onPartialMatch()
	test.isFalse(stringField:contains('partial', 'part'))
end
