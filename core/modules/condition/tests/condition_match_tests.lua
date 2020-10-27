local Condition = require('condition')

local ConditionMatchTests = test.declare('ConditionMatchTests', 'condition')


---
-- A condition with no clauses should always return true
---

function ConditionMatchTests.emptyConditions_matches()
	local cond = Condition.new({})
	test.isTrue(cond:matches(
		{},
		{}
	))
end


---
-- Scoped fields should only match against the provided scope, and not anything in
-- the table of accumulated values.
---

function ConditionMatchTests.scopeField_matches_onMatchingScope()
	local cond = Condition.new({ workspaces = 'Workspace1' })

	test.isTrue(cond:matches(
		{},
		{ workspaces = {'Workspace1'} }
	))
end


function ConditionMatchTests.scopeField_fails_onNoMatchingScope()
	local cond = Condition.new({ workspaces = 'Workspace1' })

	test.isFalse(cond:matches(
		{},
		{ workspaces = {'Workspace2'} }
	))
end


function ConditionMatchTests.scopeField_fails_onMatchingValueOnly()
	local cond = Condition.new({ projects = 'Project1' })

	test.isFalse(cond:matches(
		{ projects = {'Project1'} },
		{ workspaces = {'Workspace1'} }
	))
end


---
-- Regular non-scoped fields should match against values, and not the scope.
---

function ConditionMatchTests.valueField_matches_onMatchingValue()
	local cond = Condition.new({ defines = 'X' })

	test.isTrue(cond:matches(
		{ defines = {'X'} },
		{}
	))
end


function ConditionMatchTests.valueField_matches_onExtraValues()
	local cond = Condition.new({ defines = 'X' })

	test.isTrue(cond:matches(
		{ defines = {'X'}, kind = 'StaticLib' },
		{}
	))
end


function ConditionMatchTests.valueField_matches_onMultipleMatches()
	local cond = Condition.new({ defines = 'X', kind = 'StaticLib' })

	test.isTrue(cond:matches(
		{ defines = {'X'}, kind = 'StaticLib' },
		{}
	))
end


function ConditionMatchTests.valueField_fails_onNoMatch()
	local cond = Condition.new({ defines = 'X' })

	test.isFalse(cond:matches(
		{ defines = {'A'} },
		{}
	))
end


function ConditionMatchTests.valueField_fails_onPartialMatch()
	local cond = Condition.new({ defines = 'X', kind = 'StaticLib' })

	test.isFalse(cond:matches(
		{ defines = {'A'}, kind = 'StaticLib' },
		{}
	))
end


function ConditionMatchTests.valueField_fails_onScopeOnlyMatch()
	local cond = Condition.new({ defines = 'X' })

	test.isFalse(cond:matches(
		{ kind = 'StaticLib' },
		{ defines = {'X'} }
	))
end


function ConditionMatchTests.valueField_fails_onValueNotSet()
	local cond = Condition.new({ defines = 'X' })

	test.isFalse(cond:matches(
		{},
		{}
	))
end
