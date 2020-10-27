local Condition = require('condition')

local ConditionParsingTests = test.declare('ConditionParsingTests', 'condition')


function ConditionParsingTests.singleClause_asKeyValue()
	local cond = Condition.new({ system = 'Windows' })
	test.isTrue(cond:matches({ system = 'Windows' }))
	test.isFalse(cond:matches({ system = 'MacOS' }))
end


function ConditionParsingTests.singleClause_asStringValue()
	local cond = Condition.new({ 'system:Windows' })
	test.isTrue(cond:matches({ system = 'Windows' }))
	test.isFalse(cond:matches({ system = 'MacOS' }))
end


function ConditionParsingTests.not_asKeyValue()
	local cond = Condition.new({ system = 'not Windows' })
	test.isFalse(cond:matches({ system = 'Windows' }))
	test.isTrue(cond:matches({ system = 'MacOS' }))
end


function ConditionParsingTests.not_asStringInline()
	local cond = Condition.new({ 'system:not Windows' })
	test.isFalse(cond:matches({ system = 'Windows' }))
	test.isTrue(cond:matches({ system = 'MacOS' }))
end


function ConditionParsingTests.not_asStringPrefix()
	local cond = Condition.new({ 'not system:Windows' })
	test.isFalse(cond:matches({ system = 'Windows' }))
	test.isTrue(cond:matches({ system = 'MacOS' }))
end


function ConditionParsingTests.not_asStringInline_withMissingValue()
	local cond = Condition.new({ 'system:not Windows' })
	test.isTrue(cond:matches({}))
end


function ConditionParsingTests.not_asStringPrefix_withMissingValue()
	local cond = Condition.new({ 'not system:Windows' })
	test.isTrue(cond:matches({}))
end


function ConditionParsingTests.or_asKeyValue()
	local cond = Condition.new({ system = 'Windows or MacOS' })
	test.isTrue(cond:matches({ system = 'Windows' }))
	test.isTrue(cond:matches({ system = 'MacOS' }))
	test.isFalse(cond:matches({ system = 'Linux' }))
end


function ConditionParsingTests.or_asStringValue()
	local cond = Condition.new({ 'system:Windows or MacOS' })
	test.isTrue(cond:matches({ system = 'Windows' }))
	test.isTrue(cond:matches({ system = 'MacOS' }))
	test.isFalse(cond:matches({ system = 'Linux' }))
end


function ConditionParsingTests.or_asStringValue_withMixedFields()
	local cond = Condition.new({ 'system:Windows or kind:ConsoleApplication' })
	test.isTrue(cond:matches({ system = 'Windows' }))
	test.isTrue(cond:matches({ kind = 'ConsoleApplication' }))
	test.isFalse(cond:matches({ system = 'Linux' }))
	test.isFalse(cond:matches({ kind = 'SharedLibrary' }))
end


function ConditionParsingTests.mixedOperators_withLeadingNot()
	local cond = Condition.new({ 'not system:Windows or kind:not ConsoleApplication' })
	test.isTrue(cond:matches({ system = 'MacOS', kind = 'SharedLibrary' }))
	test.isTrue(cond:matches({ system = 'Windows', kind = 'SharedLibrary' }))
	test.isTrue(cond:matches({ system = 'MacOS', kind = 'ConsoleApplication' }))
	test.isFalse(cond:matches({ system = 'Windows', kind = 'ConsoleApplication' }))
end
