local table = require('table')

local suite = test.declare('table')

-- table.contains() --

function suite.contains_isTrue_onValueIsPresent()
	test.isTrue(table.contains({ 'one', 'two', 'three' }, 'two'))
end

function suite.contains_isFalse_onValueNotPresent()
	test.isFalse( table.contains({ 'one', 'two', 'three' }, 'four') )
end
