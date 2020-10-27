local Field = require('field')

local StringFieldTests = test.declare('StringFieldTests', 'field')


local testField

function StringFieldTests.setup()
	testField = Field.register({
		name = 'testField',
		kind = 'string'
	})
end

function StringFieldTests.teardown()
	Field.remove(testField)
end


---
-- `default()`
---

function StringFieldTests.default_isNil()
	test.isNil(testField:defaultValue())
end


---
-- `matches()`
---

function StringFieldTests.matches_isTrue_onExactMatch()
	test.isTrue(testField:matches('x', 'x', true))
end

function StringFieldTests.matches_isFalse_onMismatch()
	test.isFalse(testField:matches('x', 'y', true))
end

function StringFieldTests.matches_isFalse_onPartialMatch()
	test.isFalse(testField:matches('partial', 'part', true))
end

function StringFieldTests.matches_isFalse_onNoCurrentValue()
	test.isFalse(testField:matches(nil, 'x', true))
end


---
-- `mergeValues()` should replace any existing value
---

function StringFieldTests.mergeValues_replacesValue()
	test.isEqual('y', testField:mergeValues('x', 'y'))
end


--
-- Should raise an error is an object is assigned to a string field.
--

function StringFieldTests.mergeValues_raisesError_onTableValue()
	ok, err = pcall(function ()
		testField:mergeValues(nil, { 'a', 'b' })
	end)
	test.isFalse(ok)
end


---
-- `removeValues()` clears value
---

function StringFieldTests.removeValues_doesNothing()
	test.isNil(testField:removeValues('x', 'x'))
end
