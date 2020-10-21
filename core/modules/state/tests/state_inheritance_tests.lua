local Store = require('store')
local State = require('state')

local StateInheritanceTests = test.declare('StateInheritanceTests', 'state')


local store

function StateInheritanceTests.setup()
	store = Store.new()
end


---
-- When inheritance is enabled, `select()` should include values from
-- the immediate broader scope.
---

function StateInheritanceTests.withInheritance_includesImmediateBroaderScope_onTopLevelScopes()
	store
		:addValue('defines', 'GLOBAL')

		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('defines', 'WORKSPACE')
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')
		:popCondition()

	local project = State.new(store)
		:select({ workspaces = 'Workspace1' }) -- does not inherit
		:select({ projects = 'Project1' })
		:withInheritance()

	test.isEqual({ 'WORKSPACE', 'PROJECT' }, project:get('defines'))
end


function StateInheritanceTests.withInheritance_includesImmediateBroaderScope_onNestedScopes()
	store
		:addValue('defines', 'GLOBAL')

		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

	local project = State.new(store)
		:select({ workspaces = 'Workspace1' }) -- does not inherit
		:select({ projects = 'Project1' })
		:withInheritance()

	test.isEqual({ 'WORKSPACE', 'PROJECT' }, project:get('defines'))
end


function StateInheritanceTests.select_excludesValuesFromOuter_onNoInherit()
	store
		:pushCondition({ configuration = 'Debug' })
		:addValue('defines', 'DEBUG')
		:popCondition()

	local debugCfg = State.new(store)
		:select({ workspaces = 'Workspace1' })
		:select({ projects = 'Project1' })
		:select({ configurations = 'Debug' })

	test.isEqual({}, debugCfg:get('defines'))
end


---
-- When inheritance is enabled, and the immediate broader scope also has inheritance
-- enabled, those inherited values should also be included in the results.
---

function StateInheritanceTests.withInheritance_includesValuesInheritedByBroaderScope()
	store
		:addValue('defines', 'GLOBAL')

		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

	local project = State.new(store)
		:select({ workspaces = 'Workspace1' })
		:withInheritance()
		:select({ projects = 'Project1' })
		:withInheritance()

	test.isEqual({ 'GLOBAL', 'WORKSPACE', 'PROJECT' }, project:get('defines'))
end
