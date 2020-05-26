local Store = require('store')

local Query = require('../query')
local QueryTests = test.declare('query')


local store

function QueryTests.setup()
	store = Store.new()
end


---
-- `fetch()` should be able to retrieve values when there are no
-- conditions involved.
---

function QueryTests.fetch_returnsSimpleValue_onNoConditions()
	local query = store
		:addValue('kind', 'StaticLibrary')
		:query({})

	test.isEqual('StaticLibrary', query:fetch('kind'))
end


function QueryTests.fetch_returnsCollectionValue_onGlobalScope()
	local query = store
		:addValue('defines', { 'A', 'B' })
		:query({})

	test.isEqual({ 'A', 'B' }, query:fetch('defines'))
end


---
-- `fetch()` should return a default "empty" value for fields which have
-- not been set: `nil` for simple fields, and an empty collection for
-- collection fields.
---

function QueryTests.fetch_returnsNil_onUnsetString()
	local query = store:query({})
	test.isNil(query:fetch('kind'))
end


function QueryTests.fetch_returnsEmptyList_onUnsetList()
	local query = store:query({})
	test.isEqual({}, query:fetch('defines'))
end


---
-- Values placed behind a condition should not be returned if that
-- condition is not met.
---

function QueryTests.fetch_returnsNil_onUnmetStringCondition()
	local query = store
		:pushCondition({ system = 'Windows' })
		:addValue('kind', 'SharedLibrary')
		:query({})

	test.isNil(query:fetch('kind'))
end


function QueryTests.fetch_returnsNil_onUnmetListCondition()
	local query = store
		:pushCondition({ defines = 'X' })
		:addValue('kind', 'SharedLibrary')
		:query({})

	test.isNil(query:fetch('kind'))
end


---
-- Values behind a condition should be available once that condition is met.
---

function QueryTests.fetch_returnsValue_onStringConditionMet()
	local query = store
		:pushCondition({ system = 'Windows' })
		:addValue('kind', 'StaticLibrary')
		:query({ system = 'Windows' })

	test.isEqual('StaticLibrary', query:fetch('kind'))
end


function QueryTests.fetch_returnsValue_onListConditionMet()
	local query = store
		:pushCondition{ defines = 'X' }
		:addValue('kind', 'SharedLibrary')
		:query({ defines = 'X' })

	test.isEqual('SharedLibrary', query:fetch('kind'))
end


---
-- Not all query environment values need to be matched. Block conditions
-- which include fewer terms should be included, so long as they don't
-- aren't failed by any values in the environment.
---

function QueryTests.fetch_includesLessRestrictiveBlocks()
	local query = store
		:addValue('defines', 'OUTER')

		:pushCondition({ system = 'Windows' })
		:addValue('defines', 'INNER')

		:query({ system = 'Windows', workspaces = 'Workspace1', projects = 'Project1' })

	test.isEqual({ 'OUTER', 'INNER' }, query:fetch('defines'))
end


function QueryTests.fetch_excludesConflictingBlocks()
	local query = store
		:addValue('defines', 'OUTER')

		:pushCondition({ system = 'Windows', projects = 'Project2' })
		:addValue('defines', 'INNER')

		:query({ system = 'Windows', workspaces = 'Workspace1', projects = 'Project1' })

	test.isEqual({ 'OUTER' }, query:fetch('defines'))
end


---
-- When conditions are nested, their clauses should be combined. All clauses
-- should be met to access values.
---

function QueryTests.fetch_canAccessNestedConditions_whenAllConditionsMet()
	local query = store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

		:query({ workspaces = 'Workspace1', projects = 'Project1' })

	test.isEqual({ 'WORKSPACE', 'PROJECT' }, query:fetch('defines'))
end


function QueryTests.fetch_canNotAccessNestedConditions_whenConditionNotMet()
	local query = store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

		:query({ projects = 'Project1' })

	test.isEqual({}, query:fetch('defines'))
end


---
-- If a value is removed at the same scope where it was added, it should
-- not appear in that scope.
---

function QueryTests.remove_removesValue_whenSetAtSameScope()
	local query = store
		:addValue('defines', { 'A', 'B', 'C' })
		:removeValue('defines', 'B')
		:query({})

		test.isEqual({ 'A', 'C' }, query:fetch('defines'))
end


---
-- If a value is set at an outer scope, and then removed at a more specific
-- scope, it should not appear in that more specific scope.
---

function QueryTests.remove_removesFromOuterScopeValue_whenRemovedByInnerScope()
	local query = store
		:addValue('defines', { 'A', 'B', 'C' })
		:pushCondition({ system = 'Windows' })
		:removeValue('defines', 'B')
		:query({ system = 'Windows'})

	test.isEqual({ 'A', 'C' }, query:fetch('defines'))
end


---
-- If a value is set at an outer scope, and then removed at a more specific
-- scope, it should not appear at the outer scope.
---

function QueryTests.remove_removesFromOuterScope_whenRemovedByInnerScope()
	local query = store
		:addValue('defines', { 'A', 'B', 'C' })
		:pushCondition({ system = 'Windows' })
		:removeValue('defines', 'B')
		:query({})

	test.isEqual({ 'A', 'C' }, query:fetch('defines'))
end


---
-- If a value is set in an outer scope, and then removed at a more specific
-- scope, it should still appear in "sibling" specific scopes where it was not
-- removed.
---

function QueryTests.remove_allowsInRelatedScopes_whenRemovedAtSpecificScope()
	local query = store
		:addValue('defines', { 'A', 'B', 'C' })
		:pushCondition({ system = 'Windows' })
		:removeValue('defines', 'B')
		:query({ system = 'MacOS' })

	test.isEqual({ 'A', 'B', 'C' }, query:fetch('defines'))
end


---
-- If a scope is specified, values outside that scope should not be
-- included in the results.
---

function QueryTests.select_limitsToSelectedScope()
	local query = store
		:addValue('defines', 'GLOBAL')

		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')
		:popCondition()

		:pushCondition({ configurations = 'Debug' })
		:addValue('defines', 'DEBUG"')
		:query({})

	local workspace = query:select({ workspaces = 'Workspace1' })
	test.isEqual({ 'WORKSPACE' }, workspace:fetch('defines'))
end


---
-- When value inheritance is enabled, values from the immediate outer
-- scope should be included in the results.
---

function QueryTests.inheritValues_includesOuterScopeValues()
	local query = store
		:addValue('defines', 'GLOBAL')

		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')
		:popCondition()

		:pushCondition({ configurations = 'Debug' })
		:addValue('defines', 'DEBUG"')
		:query({})

	local project = query
		:select({ workspaces = 'Workspace1' })
		:select({ projects = 'Project1' })
		:inheritValues()

	test.isEqual({ 'WORKSPACE', 'PROJECT' }, project:fetch('defines'))
end


---
-- When value inheritance is enabled, and the immediate outer scope
-- also has inheritance enabled, those inherited values should also be
-- included in the results.
---

function QueryTests.inheritValues_includesInheritedValues()
	local query = store
		:addValue('defines', 'GLOBAL')

		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')
		:popCondition()

		:pushCondition({ configurations = 'Debug' })
		:addValue('defines', 'DEBUG')
		:query({})

	local project = query
		:select({ workspaces = 'Workspace1' })
		:select({ projects = 'Project1' })
		:inheritValues()
		:select({ configurations = 'Debug' })
		:inheritValues()

	test.isEqual({ 'WORKSPACE', 'PROJECT', 'DEBUG' }, project:fetch('defines'))
end
