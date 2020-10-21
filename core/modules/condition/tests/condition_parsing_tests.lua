local Condition = require('condition')

local ConditionParsingTests = test.declare('ConditionParsingTests', 'condition')


function ConditionParsingTests.singleClause_asKeyValue()
	local c = Condition.new({ system = 'Windows' })
	test.isTrue(c:isSatisfiedBy({ system = 'Windows' }))
	test.isFalse(c:isSatisfiedBy({ system = 'MacOS' }))
end


function ConditionParsingTests.singleClause_asStringValue()
	local c = Condition.new({ 'system:Windows' })
	test.isTrue(c:isSatisfiedBy({ system = 'Windows' }))
	test.isFalse(c:isSatisfiedBy({ system = 'MacOS' }))
end


function ConditionParsingTests.not_asKeyValue()
	local c = Condition.new({ system = 'not Windows' })
	test.isFalse(c:isSatisfiedBy({ system = 'Windows' }))
	test.isTrue(c:isSatisfiedBy({ system = 'MacOS' }))
end


function ConditionParsingTests.not_asStringInline()
	local c = Condition.new({ 'system:not Windows' })
	test.isFalse(c:isSatisfiedBy({ system = 'Windows' }))
	test.isTrue(c:isSatisfiedBy({ system = 'MacOS' }))
end


function ConditionParsingTests.not_asStringPrefix()
	local c = Condition.new({ 'not system:Windows' })
	test.isFalse(c:isSatisfiedBy({ system = 'Windows' }))
	test.isTrue(c:isSatisfiedBy({ system = 'MacOS' }))
end


function ConditionParsingTests.not_asStringInline_withMissingValue()
	local c = Condition.new({ 'system:not Windows' })
	test.isTrue(c:isSatisfiedBy({}))
end


function ConditionParsingTests.not_asStringPrefix_withMissingValue()
	local c = Condition.new({ 'not system:Windows' })
	test.isTrue(c:isSatisfiedBy({}))
end


function ConditionParsingTests.or_asKeyValue()
	local c = Condition.new({ system = 'Windows or MacOS' })
	test.isTrue(c:isSatisfiedBy({ system = 'Windows' }))
	test.isTrue(c:isSatisfiedBy({ system = 'MacOS' }))
	test.isFalse(c:isSatisfiedBy({ system = 'Linux' }))
end


function ConditionParsingTests.or_asStringValue()
	local c = Condition.new({ 'system:Windows or MacOS' })
	test.isTrue(c:isSatisfiedBy({ system = 'Windows' }))
	test.isTrue(c:isSatisfiedBy({ system = 'MacOS' }))
	test.isFalse(c:isSatisfiedBy({ system = 'Linux' }))
end


function ConditionParsingTests.or_asStringValue_withMixedFields()
	local c = Condition.new({ 'system:Windows or kind:ConsoleApplication' })
	test.isTrue(c:isSatisfiedBy({ system = 'Windows' }))
	test.isTrue(c:isSatisfiedBy({ kind = 'ConsoleApplication' }))
	test.isFalse(c:isSatisfiedBy({ system = 'Linux' }))
	test.isFalse(c:isSatisfiedBy({ kind = 'SharedLibrary' }))
end


function ConditionParsingTests.mixedOperators_withLeadingNot()
	local c = Condition.new({ 'not system:Windows or kind:not ConsoleApplication' })
	test.isTrue(c:isSatisfiedBy({ system = 'MacOS', kind = 'SharedLibrary' }))
	test.isTrue(c:isSatisfiedBy({ system = 'Windows', kind = 'SharedLibrary' }))
	test.isTrue(c:isSatisfiedBy({ system = 'MacOS', kind = 'ConsoleApplication' }))
	test.isFalse(c:isSatisfiedBy({ system = 'Windows', kind = 'ConsoleApplication' }))
end
