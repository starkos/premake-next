local Condition = require('../condition')

local ConditionTests = test.declare('ConditionTests')


---
-- `new()` should return an object and not crash.
---

function ConditionTests.new_returnsObject()
	test.isNotNil(Condition.new({}))
end


---
-- `isSatisfiedBy()` should return true if all clauses have matching, non-nil values
---

function ConditionTests.isSatisfiedBy_isTrue_onMatchingValue()
	local c = Condition.new({ projects = 'Project1' })
	test.isTrue(c:isSatisfiedBy({ projects = 'Project1' }))
end


function ConditionTests.isSatisfiedBy_isTrue_onExtraValues()
	local c = Condition.new({ projects = 'Project1' })
	test.isTrue(c:isSatisfiedBy({ workspaces = 'Workspace1', projects = 'Project1' }))
end


function ConditionTests.isSatisfiedBy_isTrue_onMultipleMatches()
	local c = Condition.new({ workspaces = 'Workspace1', projects = 'Project1' })
	test.isTrue(c:isSatisfiedBy({ workspaces = 'Workspace1', projects = 'Project1' }))
end


function ConditionTests.isSatisfiedBy_isFalse_onMissingValue()
	local c = Condition.new({ projects = 'Project1' })
	test.isFalse(c:isSatisfiedBy({}))
end


function ConditionTests.isSatisfiedBy_isFalse_onMismatchedValue()
	local c = Condition.new({ projects = 'Project1' })
	test.isFalse(c:isSatisfiedBy({ projects = 'Project2' }))
end


function ConditionTests.isSatisfiedBy_isFalse_onMixedResults()
	local c = Condition.new({ workspaces = 'Workspace1', projects = 'Project1' })
	test.isFalse(c:isSatisfiedBy({ workspaces = 'Workspace1', projects = 'Project2' }))
end


---
-- `isNotFailedBy` should return true if all clauses have a matching value, or no
-- value (`nil`). Should return false if any value fails a clause.
---

function ConditionTests.isNotFailedBy_isTrue_onValueMatch()
	local c = Condition.new({ kind = 'StaticLibrary' })
	test.isTrue(c:isNotFailedBy({ kind = 'StaticLibrary' }))
end


function ConditionTests.isNotFailedBy_isTrue_onValueMissing()
	local c = Condition.new({ kind = 'StaticLibrary' })
	test.isTrue(c:isNotFailedBy({}))
end

function ConditionTests.isNotFailedBy_isFalse_onValueMismatch()
	local c = Condition.new({ kind = 'StaticLibrary' })
	test.isFalse(c:isNotFailedBy({ kind = 'ConsoleApplication' }))
end


---
-- Test parsing of user specified conditions
---

function ConditionTests.singleClause_asKeyValue_withStringField()
	local c = Condition.new({ system = 'Windows' })
	test.isTrue(c:isSatisfiedBy({ system = 'Windows' }))
	test.isFalse(c:isSatisfiedBy({ system = 'MacOS' }))
end
