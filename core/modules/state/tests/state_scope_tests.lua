local Store = require('store')
local State = require('state')

local StateScopeTests = test.declare('StateScopeTests', 'state')


local store

function StateScopeTests.setup()
	store = Store.new()
end



---
-- When conditions are nested, their clauses should be combined. All clauses
-- should be met to access values.
---

function StateScopeTests.get_includesNestedBlock_whenCombinedConditionsMet()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

	local state = State.new(store, { workspaces = 'Workspace1', projects = 'Project1' })
	test.isEqual({ 'WORKSPACE', 'PROJECT' }, state:get('defines'))
end


function StateScopeTests.get_excludesNestedBlock_whenCombinedConditionsNotMet()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

	local state = State.new(store, { projects = 'Project1' })
	test.isEqual({}, state:get('defines'))
end


---
-- When `select()` is used pull out a specific scope, any values that fall
-- outside of that scope should not be included in the results.
---

function StateScopeTests.select_limitsToSelectedScope_onTopLevelScopes()
	store
		:addValue('defines', 'GLOBAL')

		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')
		:popCondition()

		:pushCondition({ configurations = 'Debug' })
		:addValue('defines', 'DEBUG"')

	local workspace = State.new(store)
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'WORKSPACE' }, workspace:get('defines'))
end


function StateScopeTests.select_limitsToSelectedScope_onNestedScopes()
	store
		:addValue('defines', 'GLOBAL')

		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

		:pushCondition({ configurations = 'Debug' })
		:addValue('defines', 'DEBUG"')

	local workspace = State.new(store)
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'WORKSPACE' }, workspace:get('defines'))
end
