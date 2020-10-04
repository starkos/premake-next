local Query = require('../query')
local Store = require('store')

local QueryTests = test.declare('query')


local store

function QueryTests.setup()
	store = Store.new()
end


---
-- `fetch()` should be able to retrieve values when no conditions are involved.
---

function QueryTests.fetch_returnsSimpleValue_onNoConditions()
	store:addValue('kind', 'StaticLibrary')
	test.isEqual('StaticLibrary', store:query():fetch('kind'))
end


function QueryTests.fetch_returnsCollectionValue_onGlobalScope()
	store:addValue('defines', { 'A', 'B' })
	test.isEqual({ 'A', 'B' }, store:query():fetch('defines'))
end


---
-- `fetch()` should return a default "empty" value for fields which have not been
-- set: `nil` for simple fields, and an empty collection for collection fields.
---

function QueryTests.fetch_returnsNil_onUnsetString()
	test.isNil(store:query():fetch('kind'))
end


function QueryTests.fetch_returnsEmptyList_onUnsetList()
	test.isEqual({}, store:query():fetch('defines'))
end


---
-- Values placed behind a condition should not be returned if condition is not met.
---

function QueryTests.fetch_returnsNil_onUnmetStringCondition()
	store
		:pushCondition({ system = 'Windows' })
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	test.isNil(store:query():fetch('kind'))
end


function QueryTests.fetch_returnsNil_onUnmetListCondition()
	store
		:pushCondition({ defines = 'X' })
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	test.isNil(store:query():fetch('kind'))
end


---
-- Values behind a condition should be available once that condition is met.
---

function QueryTests.fetch_returnsValue_onStringConditionMet()
	store
		:pushCondition({ system = 'Windows' })
		:addValue('kind', 'StaticLibrary')
		:popCondition()

	local query = store:query({ system = 'Windows' })
	test.isEqual('StaticLibrary', query:fetch('kind'))
end


function QueryTests.fetch_returnsValue_onListConditionMet()
	store
		:pushCondition{ defines = 'X' }
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	local query = store:query({ defines = 'X' })
	test.isEqual('SharedLibrary', query:fetch('kind'))
end


---
-- When conditions are nested, their clauses should be combined. All clauses
-- should be met to access values.
---

function QueryTests.fetch_includesNestedBlock_whenCombinedConditionsMet()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

	local query = store:query({ workspaces = 'Workspace1', projects = 'Project1' })
	test.isEqual({ 'WORKSPACE', 'PROJECT' }, query:fetch('defines'))
end


function QueryTests.fetch_excludesNestedBlock_whenCombinedConditionsNotMet()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

	local query = store:query({ projects = 'Project1' })
	test.isEqual({}, query:fetch('defines'))
end


---
-- When `select()` is used pull out a specific scope, any values that fall
-- outside of that scope should not be included in the results.
---

function QueryTests.select_limitsToSelectedScope_onTopLevelScopes()
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

	local workspace = store:query()
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'WORKSPACE' }, workspace:fetch('defines'))
end


function QueryTests.select_limitsToSelectedScope_onNestedScopes()
	store
		:addValue('defines', 'GLOBAL')

		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

		:pushCondition({ configurations = 'Debug' })
		:addValue('defines', 'DEBUG"')

	local workspace = store:query()
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'WORKSPACE' }, workspace:fetch('defines'))
end


function QueryTests.select_excludesValuesFromOuter_onNoInherit()
	store
		:pushCondition({ configuration = 'Debug' })
		:addValue('defines', 'DEBUG')
		:popCondition()

	local debugCfg = store:query()
		:select({ workspaces = 'Workspace1' })
		:select({ projects = 'Project1' })
		:select({ configurations = 'Debug' })

	test.isEqual({}, debugCfg:fetch('defines'))
end


---
-- When inheritance is enabled, `select()` should include values from
-- the immediate broader scope.
---

function QueryTests.inheritValues_includesImmediateBroaderScope_onTopLevelScopes()
	store
		:addValue('defines', 'GLOBAL')

		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('defines', 'WORKSPACE')
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')
		:popCondition()

	local project = store:query()
		:select({ workspaces = 'Workspace1' }) -- does not inherit
		:select({ projects = 'Project1' }):inheritValues()

	test.isEqual({ 'WORKSPACE', 'PROJECT' }, project:fetch('defines'))
end


function QueryTests.inheritValues_includesImmediateBroaderScope_onNestedScopes()
	store
		:addValue('defines', 'GLOBAL')

		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

	local project = store:query()
		:select({ workspaces = 'Workspace1' }) -- does not inherit
		:select({ projects = 'Project1' }):inheritValues()

	test.isEqual({ 'WORKSPACE', 'PROJECT' }, project:fetch('defines'))
end


---
-- When inheritance is enabled, and the immediate broader scope also has inheritance
-- enabled, those inherited values should also be included in the results.
---

function QueryTests.inheritValues_includesValuesInheritedByBroaderScope()
	store
		:addValue('defines', 'GLOBAL')

		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', 'WORKSPACE')
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:addValue('defines', 'PROJECT')

	local project = store:query()
		:select({ workspaces = 'Workspace1' }):inheritValues()
		:select({ projects = 'Project1' }):inheritValues()

	test.isEqual({ 'GLOBAL', 'WORKSPACE', 'PROJECT' }, project:fetch('defines'))
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

function QueryTests.remove_byWorkspace()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ workspaces = 'Workspace1' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local workspace = store:query()
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'VALUE1', 'VALUE3' }, workspace:fetch('defines'))
end


function QueryTests.remove_byProject()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:removeValue('defines', 'VALUE2')

	local workspace = store:query()
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'VALUE1', 'VALUE3' }, workspace:fetch('defines'))
end


function QueryTests.remove_byNestedProject()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })

		:pushCondition({ projects = 'Project1' })
		:removeValue('defines', 'VALUE2')

	local workspace = store:query()
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'VALUE1', 'VALUE3' }, workspace:fetch('defines'))
end


function QueryTests.remove_byUnrelatedProject_isIgnored()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project2' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local workspace = store:query()
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'VALUE1', 'VALUE2', 'VALUE3' }, workspace:fetch('defines'))
end


function QueryTests.remove_byProject_appearsInOtherProjects()
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

	local project2 = store:query()
		:select({ workspaces = 'Workspace1'})
		:select({ projects = 'Project2 '}):inheritValues()

	test.isEqual({ 'VALUE1', 'VALUE2', 'VALUE3' }, project2:fetch('defines'))
end


---
-- If a value defined at a broader scope (workspace) is removed from a narrower
-- scope (project), the other siblings of that narrower scope (other projects)
-- should still receive the removed value, _even if inheritance is disabled._
-- Since the value would not be set in the exported workspace, it must be set in
-- the exported project or it won't be set at all.
---

function QueryTests.remove_byProject_appearsInOtherProjects_noInheritance()
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

	local project2 = store:query()
		:select({ workspaces = 'Workspace1'})
		:select({ projects = 'Project2 '})

	test.isEqual({ 'VALUE2' }, project2:fetch('defines'))
end


function QueryTests.remove_fromConfig_byProject()
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

	local debugCfg = store:query()
		:select({ workspaces = 'Workspace1'})
		:select({ configurations = 'Debug'}):inheritValues()

	test.isEqual({ 'DEBUG1', 'DEBUG3' }, debugCfg:fetch('defines'))
end


function QueryTests.remove_fromConfig_byProject_noInheritance()
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

	local debugCfg = store:query()
		:select({ workspaces = 'Workspace1'})
		:select({ configurations = 'Debug'})

	test.isEqual({ 'DEBUG1', 'DEBUG3' }, debugCfg:fetch('defines'))
end


---
-- The same remove tests, but now working at the configuration level to make sure
-- things still work when spread over additional layers of scoping.
---

function QueryTests.remove_byProjectConfig()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('configurations', { 'Debug', 'Release' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1', configurations = 'Debug' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local workspace = store:query()
		:select({ workspaces = 'Workspace1' })

	test.isEqual({ 'VALUE1', 'VALUE3' }, workspace:fetch('defines'))
end


function QueryTests.remove_byProjectConfig_appearsInOtherConfigs()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('configurations', { 'Debug', 'Release' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1', configurations = 'Debug' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local releaseCfg = store:query()
		:select({ workspaces = 'Workspace1' })
		:select({ projects = 'Project1' }):inheritValues()
		:select({ configurations = 'Release' }):inheritValues()

	test.isEqual({ 'VALUE1', 'VALUE2', 'VALUE3' }, releaseCfg:fetch('defines'))
end


function QueryTests.remove_byProjectConfig_appearsInOtherConfigs_noInheritance()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('configurations', { 'Debug', 'Release' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1', configurations = 'Debug' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local releaseCfg = store:query()
		:select({ workspaces = 'Workspace1' })
		:select({ projects = 'Project1' })
		:select({ configurations = 'Release' })

	test.isEqual({ 'VALUE2' }, releaseCfg:fetch('defines'))
end


function QueryTests.remove_byProjectConfig_appearsInOtherConfigs_mixedInheritance()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('configurations', { 'Debug', 'Release' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1', configurations = 'Debug' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local releaseCfg = store:query()
		:select({ workspaces = 'Workspace1' })
		:select({ projects = 'Project1' })
		:select({ configurations = 'Release' }):inheritValues()

	test.isEqual({ 'VALUE2' }, releaseCfg:fetch('defines'))
end


---
-- It should be possible to test for values that haven't been set yet (i.e. setting up
-- target type specific settings at the global or workspace level, when `kind` isn't set
-- until projects are configured later).
---

function QueryTests.canEvaluateBlocksOutOfOrder()
	store
		:pushCondition({ kind = 'StaticLibrary' })
		:addValue('defines', 'STATIC')
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:addValue('kind', 'StaticLibrary')
		:addValue('defines', 'PROJECT')
		:popCondition()

	local project = store:query()
		:select({ projects = 'Project1' }):inheritValues()

	test.isEqual({ 'STATIC', 'PROJECT' }, project:fetch('defines'))
end
