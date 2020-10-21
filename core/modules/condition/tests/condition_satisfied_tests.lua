local Condition = require('condition')

local ConditionSatisfiedTests = test.declare('ConditionSatisfiedTests', 'condition')


---
-- `isSatisfiedBy()` should return true if all clauses have matching, non-nil values
---

function ConditionSatisfiedTests.isSatisfiedBy_isTrue_onMatchingValue()
	local c = Condition.new({ projects = 'Project1' })
	test.isTrue(c:isSatisfiedBy({ projects = 'Project1' }))
end


function ConditionSatisfiedTests.isSatisfiedBy_isTrue_onExtraValues()
	local c = Condition.new({ projects = 'Project1' })
	test.isTrue(c:isSatisfiedBy({ workspaces = 'Workspace1', projects = 'Project1' }))
end


function ConditionSatisfiedTests.isSatisfiedBy_isTrue_onMultipleMatches()
	local c = Condition.new({ workspaces = 'Workspace1', projects = 'Project1' })
	test.isTrue(c:isSatisfiedBy({ workspaces = 'Workspace1', projects = 'Project1' }))
end


function ConditionSatisfiedTests.isSatisfiedBy_isFalse_onMissingValue()
	local c = Condition.new({ projects = 'Project1' })
	test.isFalse(c:isSatisfiedBy({}))
end


function ConditionSatisfiedTests.isSatisfiedBy_isFalse_onMismatchedValue()
	local c = Condition.new({ projects = 'Project1' })
	test.isFalse(c:isSatisfiedBy({ projects = 'Project2' }))
end


function ConditionSatisfiedTests.isSatisfiedBy_isFalse_onMixedResults()
	local c = Condition.new({ workspaces = 'Workspace1', projects = 'Project1' })
	test.isFalse(c:isSatisfiedBy({ workspaces = 'Workspace1', projects = 'Project2' }))
end
