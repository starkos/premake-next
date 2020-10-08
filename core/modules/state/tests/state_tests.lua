local StateTests = test.declare('state')

local Store = require('store')
local State = require('state')


local store

function StateTests.setup()
	store = Store.new()
end


---
-- `get()` should be able to retrieve values when no conditions are involved.
---

function StateTests.get_returnsSimpleValue_onNoConditions()
	store:addValue('kind', 'StaticLibrary')
	test.isEqual('StaticLibrary', State.new(store):get('kind'))
end


function StateTests.get_returnsCollectionValue_onGlobalScope()
	store:addValue('defines', { 'A', 'B' })
	test.isEqual({ 'A', 'B' }, State.new(store):get('defines'))
end


---
-- `get()` should return a default "empty" value for fields which have not been
-- set: `nil` for simple fields, and an empty collection for collection fields.
---

function StateTests.get_returnsNil_onUnsetString()
	test.isNil(State.new(store):get('kind'))
end


function StateTests.get_returnsEmptyList_onUnsetList()
	test.isEqual({}, State.new(store):get('defines'))
end


---
-- Values placed behind a condition should not be returned if condition is not met.
---

function StateTests.get_returnsNil_onUnmetStringCondition()
	store
		:pushCondition({ system = 'Windows' })
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	test.isNil(State.new(store):get('kind'))
end


function StateTests.get_returnsNil_onUnmetListCondition()
	store
		:pushCondition({ defines = 'X' })
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	test.isNil(State.new(store):get('kind'))
end


---
-- Values behind a condition should be available once that condition is met.
---

function StateTests.get_returnsValue_onStringConditionMet()
	store
		:pushCondition({ system = 'Windows' })
		:addValue('kind', 'StaticLibrary')
		:popCondition()

	local state = State.new(store, { system = 'Windows' })
	test.isEqual('StaticLibrary', state:get('kind'))
end


function StateTests.get_returnsValue_onListConditionMet()
	store
		:pushCondition{ defines = 'X' }
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	local state = State.new(store, { defines = 'X' })
	test.isEqual('SharedLibrary', state:get('kind'))
end


---
-- When conditions are nested, their clauses should be combined. All clauses
-- should be met to access values.
---

function StateTests.get_includesNestedBlock_whenCombinedConditionsMet()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

	local state = State.new(store, { workspaces = 'Workspace1', projects = 'Project1' })
	test.isEqual({ 'WORKSPACE', 'PROJECT' }, state:get('defines'))
end


function StateTests.get_excludesNestedBlock_whenCombinedConditionsNotMet()
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

function StateTests.select_limitsToSelectedScope_onTopLevelScopes()
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


function StateTests.select_limitsToSelectedScope_onNestedScopes()
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


function StateTests.select_excludesValuesFromOuter_onNoInherit()
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
-- When inheritance is enabled, `select()` should include values from
-- the immediate broader scope.
---

function StateTests.withInheritance_includesImmediateBroaderScope_onTopLevelScopes()
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


function StateTests.withInheritance_includesImmediateBroaderScope_onNestedScopes()
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


---
-- When inheritance is enabled, and the immediate broader scope also has inheritance
-- enabled, those inherited values should also be included in the results.
---

function StateTests.withInheritance_includesValuesInheritedByBroaderScope()
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


---
-- When a value is defined at a broader scope, like a workspace, and then removed
-- from a narrower scope, like a project, the value must not appear in query results
-- for broader scope. Since most toolsets only support additive configuration, once
-- the define exported to the workspace there would be no way to remove it when
-- exporting the project. The only way to make this work is to _not_ export the
-- value at the workspace, and instead move it to those narrower scopes where it
-- was not removed.
---

function StateTests.remove_byWorkspace()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ workspaces = 'Workspace1' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local workspace = State.new(store)
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'VALUE1', 'VALUE3' }, workspace:get('defines'))
end


function StateTests.remove_byProject()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:removeValue('defines', 'VALUE2')

	local workspace = State.new(store)
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'VALUE1', 'VALUE3' }, workspace:get('defines'))
end


function StateTests.remove_byNestedProject()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })

		:pushCondition({ projects = 'Project1' })
		:removeValue('defines', 'VALUE2')

	local workspace = State.new(store)
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'VALUE1', 'VALUE3' }, workspace:get('defines'))
end


function StateTests.remove_byUnrelatedProject_isIgnored()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project2' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local workspace = State.new(store)
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'VALUE1', 'VALUE2', 'VALUE3' }, workspace:get('defines'))
end


function StateTests.remove_byProject_appearsInOtherProjects()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', { 'Project1', 'Project2' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

		:pushCondition({ projects = 'Project2' })
		:popCondition()

	local project2 = State.new(store)
		:select({ workspaces = 'Workspace1'})
		:select({ projects = 'Project2 '})
		:withInheritance()

	test.isEqual({ 'VALUE1', 'VALUE2', 'VALUE3' }, project2:get('defines'))
end


---
-- If a value defined at a broader scope (workspace) is removed from a narrower
-- scope (project), the other siblings of that narrower scope (other projects)
-- should still receive the removed value, _even if inheritance is disabled._
-- Since the value would not be set in the exported workspace, it must be set in
-- the exported project or it won't be set at all.
---

function StateTests.remove_byProject_appearsInOtherProjects_noInheritance()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', { 'Project1', 'Project2' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

		:pushCondition({ projects = 'Project2' })
		:popCondition()

	local project2 = State.new(store)
		:select({ workspaces = 'Workspace1'})
		:select({ projects = 'Project2 '})

	test.isEqual({ 'VALUE2' }, project2:get('defines'))
end


function StateTests.remove_fromConfig_byProject()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', { 'Project1' })
		:addValue('configurations', { 'Debug', 'Release '})
		:popCondition()

		:pushCondition({ configurations = 'Debug' })
		:addValue('defines', { 'DEBUG1', 'DEBUG2', 'DEBUG3' })
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:removeValue('defines', 'DEBUG2')
		:popCondition()

	local debugCfg = State.new(store)
		:select({ workspaces = 'Workspace1'})
		:select({ configurations = 'Debug'})
		:withInheritance()

	test.isEqual({ 'DEBUG1', 'DEBUG3' }, debugCfg:get('defines'))
end


function StateTests.remove_fromConfig_byProject_noInheritance()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', { 'Project1' })
		:addValue('configurations', { 'Debug', 'Release '})
		:popCondition()

		:pushCondition({ configurations = 'Debug' })
		:addValue('defines', { 'DEBUG1', 'DEBUG2', 'DEBUG3' })
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:removeValue('defines', 'DEBUG2')
		:popCondition()

	local debugCfg = State.new(store)
		:select({ workspaces = 'Workspace1'})
		:select({ configurations = 'Debug'})

	test.isEqual({ 'DEBUG1', 'DEBUG3' }, debugCfg:get('defines'))
end


---
-- The same remove tests, but now working at the configuration level to make sure
-- things still work when spread over additional layers of scoping.
---

function StateTests.remove_byProjectConfig()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('configurations', { 'Debug', 'Release' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1', configurations = 'Debug' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local workspace = State.new(store)
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'VALUE1', 'VALUE3' }, workspace:get('defines'))
end


function StateTests.remove_byProjectConfig_appearsInOtherConfigs()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('configurations', { 'Debug', 'Release' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1', configurations = 'Debug' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local releaseCfg = State.new(store)
		:select({ workspaces = 'Workspace1' })
		:select({ projects = 'Project1' })
		:withInheritance()
		:select({ configurations = 'Release' })
		:withInheritance()

	test.isEqual({ 'VALUE1', 'VALUE2', 'VALUE3' }, releaseCfg:get('defines'))
end


function StateTests.remove_byProjectConfig_appearsInOtherConfigs_noInheritance()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('configurations', { 'Debug', 'Release' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1', configurations = 'Debug' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local releaseCfg = State.new(store)
		:select({ workspaces = 'Workspace1' })
		:select({ projects = 'Project1' })
		:select({ configurations = 'Release' })

	test.isEqual({ 'VALUE2' }, releaseCfg:get('defines'))
end


function StateTests.remove_byProjectConfig_appearsInOtherConfigs_mixedInheritance()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('configurations', { 'Debug', 'Release' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1', configurations = 'Debug' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local releaseCfg = State.new(store)
		:select({ workspaces = 'Workspace1' })
		:select({ projects = 'Project1' })
		:select({ configurations = 'Release' })
		:withInheritance()

	test.isEqual({ 'VALUE2' }, releaseCfg:get('defines'))
end


---
-- It should be possible to test for values that haven't been set yet (i.e. setting up
-- target type specific settings at the global or workspace level, when `kind` isn't set
-- until projects are configured later).
---

function StateTests.canEvaluateBlocksOutOfOrder()
	store
		:pushCondition({ kind = 'StaticLibrary' })
		:addValue('defines', 'STATIC')
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:addValue('kind', 'StaticLibrary')
		:addValue('defines', 'PROJECT')
		:popCondition()

	local project = State.new(store)
		:select({ projects = 'Project1' })
		:withInheritance()

	test.isEqual({ 'STATIC', 'PROJECT' }, project:get('defines'))
end
