local Store = require('store')
local State = require('state')

local StateScopeTests = test.declare('StateScopeTests', 'state')


local store

function StateScopeTests.setup()
	store = Store.new()
end


---
-- Sanity test: testing top-level scopes with no environment
---

function StateScopeTests.returnsValue_onScopeMet()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')

	local state = State.new(store)
		:select('workspaces', 'Workspace1')

	test.isEqual({ 'WORKSPACE' }, state:get('defines'))
end

function StateScopeTests.returnsNil_onScopeNotMet()
	store
		:pushCondition({ workspaces = 'Workspace2' })
		:addValue('defines', 'WORKSPACE')

	local state = State.new(store)
		:select('workspaces', 'Workspace1')

	test.isEqual({}, state:get('defines'))
end


---
-- In order to be included, blocks must specifically test for the scope
---

function StateScopeTests.returnsNil_onScopeNotTested()
	store
		:pushCondition({ system = 'Windows' })
		:addValue('defines', 'SYSTEM')

	local state = State.new(store, { system = 'Windows' })
		:select('workspaces', 'Workspace1')

	test.isEqual({}, state:get('defines'))
end

function StateScopeTests.excludesGlobalValues_onScopeNotTested()
	store
		:addValue('defines', 'SYSTEM')

	local state = State.new(store, { system = 'Windows' })
		:select('workspaces', 'Workspace1')

	test.isEqual({}, state:get('defines'))
end


---
-- When scopes are nested, all levels must be matched
---

function StateScopeTests.returnsValue_onNestedScopesMatched()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')
		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

	local state = State.new(store)
		:select('workspaces', 'Workspace1')
		:select('projects', 'Project1')

	test.isEqual({ 'PROJECT' }, state:get('defines'))
end

function StateScopeTests.returnsNil_onOuterScopeMismatch()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')
		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

	local state = State.new(store)
		:select('workspaces', 'Workspace2')
		:select('projects', 'Project1')

	test.isEqual({}, state:get('defines'))
end

function StateScopeTests.returnsNil_onInnerScopeMismatch()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')
		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

	local state = State.new(store)
		:select('workspaces', 'Workspace1')
		:select('projects', 'Project2')

	test.isEqual({}, state:get('defines'))
end
