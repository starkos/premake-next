local Condition = require('condition')

local ConditionParsingTests = test.declare('ConditionParsingTests', 'condition')


function ConditionParsingTests.singleClause_asKeyValue()
	local cond = Condition.new({ system = 'Windows' })
	test.isTrue(cond:matchesValues({ system = 'Windows' }))
	test.isFalse(cond:matchesValues({ system = 'MacOS' }))
end


function ConditionParsingTests.singleClause_asStringValue()
	local cond = Condition.new({ 'system:Windows' })
	test.isTrue(cond:matchesValues({ system = 'Windows' }))
	test.isFalse(cond:matchesValues({ system = 'MacOS' }))
end


function ConditionParsingTests.not_asKeyValue()
	local cond = Condition.new({ system = 'not Windows' })
	test.isFalse(cond:matchesValues({ system = 'Windows' }))
	test.isTrue(cond:matchesValues({ system = 'MacOS' }))
end


function ConditionParsingTests.not_asStringInline()
	local cond = Condition.new({ 'system:not Windows' })
	test.isFalse(cond:matchesValues({ system = 'Windows' }))
	test.isTrue(cond:matchesValues({ system = 'MacOS' }))
end


function ConditionParsingTests.not_asStringPrefix()
	local cond = Condition.new({ 'not system:Windows' })
	test.isFalse(cond:matchesValues({ system = 'Windows' }))
	test.isTrue(cond:matchesValues({ system = 'MacOS' }))
end


function ConditionParsingTests.not_asStringInline_withMissingValue()
	local cond = Condition.new({ 'system:not Windows' })
	test.isTrue(cond:matchesValues({}))
end


function ConditionParsingTests.not_asStringPrefix_withMissingValue()
	local cond = Condition.new({ 'not system:Windows' })
	test.isTrue(cond:matchesValues({}))
end


function ConditionParsingTests.or_asKeyValue()
	local cond = Condition.new({ system = 'Windows or MacOS' })
	test.isTrue(cond:matchesValues({ system = 'Windows' }))
	test.isTrue(cond:matchesValues({ system = 'MacOS' }))
	test.isFalse(cond:matchesValues({ system = 'Linux' }))
end


function ConditionParsingTests.or_asStringValue()
	local cond = Condition.new({ 'system:Windows or MacOS' })
	test.isTrue(cond:matchesValues({ system = 'Windows' }))
	test.isTrue(cond:matchesValues({ system = 'MacOS' }))
	test.isFalse(cond:matchesValues({ system = 'Linux' }))
end


function ConditionParsingTests.or_asStringValue_withMixedFields()
	local cond = Condition.new({ 'system:Windows or kind:ConsoleApplication' })
	test.isTrue(cond:matchesValues({ system = 'Windows' }))
	test.isTrue(cond:matchesValues({ kind = 'ConsoleApplication' }))
	test.isFalse(cond:matchesValues({ system = 'Linux' }))
	test.isFalse(cond:matchesValues({ kind = 'SharedLibrary' }))
end


function ConditionParsingTests.mixedOperators_withLeadingNot()
	local cond = Condition.new({ 'not system:Windows or kind:not ConsoleApplication' })
	test.isTrue(cond:matchesValues({ system = 'MacOS', kind = 'SharedLibrary' }))
	test.isTrue(cond:matchesValues({ system = 'Windows', kind = 'SharedLibrary' }))
	test.isTrue(cond:matchesValues({ system = 'MacOS', kind = 'ConsoleApplication' }))
	test.isFalse(cond:matchesValues({ system = 'Windows', kind = 'ConsoleApplication' }))
end
