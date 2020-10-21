local Field = require('field')

local StringFieldTests = test.declare('StringFieldTests', 'field')


local testField

function StringFieldTests.setup()
	testField = Field.new({
		name = 'testField',
		kind = 'string'
	})
end

function StringFieldTests.teardown()
	Field.delete(testField)
end


---
-- `addValue()` should replace simple values
---

function StringFieldTests.addValue_setSimpleValue()
	test.isEqual('newValue', testField:mergeValues(nil, 'newValue'))
end

function StringFieldTests.addValue_replacesSimpleValue()
	test.isEqual('y', testField:mergeValues('x', 'y'))
end


---
-- `removeValue()` should leave value alone
---

function StringFieldTests.removeValues_removes_onMatchingValue()
	test.isEqual('x', testField:removeValues('x', 'x'))
end


---
-- `canMatchPattern()` should return true if the provided pattern can be
-- matched against the field's value.
---

function StringFieldTests.contains_isTrue_onSimpleValueMatch()
	test.isTrue(testField:contains('x', 'x'))
end

function StringFieldTests.contains_isFalse_onSimpleValueMismatch()
	test.isFalse(testField:contains('x', 'y'))
end
