local Store = require('store')
local State = require('state')

local StateRemoveTests = test.declare('StateRemoveTests', 'state')


local store

function StateRemoveTests.setup()
	store = Store.new()
end


---
-- When a value is defined at a broader scope, like a workspace, and then removed
-- from a narrower scope, like a project, the value must not appear in query results
-- for broader scope. Since most toolsets only support additive configuration, once
-- the define gets exported to the workspace there would be no way to remove it at
-- the project level. The only way to make this work is to _not_ export the value
-- value at the workspace, and instead move it to those narrower scopes where it
-- it was _not_ removed, and should still be applied.
---

function StateRemoveTests.removedByWorkspace_shouldRemoveFromWorkspace()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ workspaces = 'Workspace1' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local workspace = State.new(store)
		:select('workspaces', 'Workspace1')

	test.isEqual({ 'VALUE1', 'VALUE3' }, workspace:get('defines'))
end


function StateRemoveTests.removedByProject_shouldRemoveFromWorkspace()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project1' })
		:removeValue('defines', 'VALUE2')

	local workspace = State.new(store)
		:select('workspaces', 'Workspace1')

	test.isEqual({ 'VALUE1', 'VALUE3' }, workspace:get('defines'))
end


function StateRemoveTests.removedByNestedProject_shouldRemoveFromWorkspace()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })

		:pushCondition({ projects = 'Project1' })
		:removeValue('defines', 'VALUE2')

	local workspace = State.new(store)
		:select('workspaces', 'Workspace1')

	test.isEqual({ 'VALUE1', 'VALUE3' }, workspace:get('defines'))
end


function StateRemoveTests.removedByConfig_shouldRemoveFromWorkspace()
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
		:select('workspaces', 'Workspace1')

	test.isEqual({ 'VALUE1', 'VALUE3' }, workspace:get('defines'))
end


---
-- Values removed from projects which aren't part of the workspace should be ignored
---

function StateRemoveTests.removedByUnrelatedProject_shouldBeIgnored()
	store
		:pushCondition({ workspaces = 'Workspace1' })
		:addValue('projects', 'Project1')
		:addValue('defines', { 'VALUE1', 'VALUE2', 'VALUE3' })
		:popCondition()

		:pushCondition({ projects = 'Project2' })
		:removeValue('defines', 'VALUE2')
		:popCondition()

	local workspace = State.new(store)
		:select('workspaces', 'Workspace1')

	test.isEqual({ 'VALUE1', 'VALUE2', 'VALUE3' }, workspace:get('defines'))
end



---
-- If a value defined at a broader scope (workspace) is removed from a narrower
-- scope (project), the other siblings of that narrower scope (other projects)
-- should still receive the removed value, _even if inheritance is disabled._
-- Since the value would not be set in the exported workspace, it must be set in
-- the exported project or it won't be set at all.
---

function StateRemoveTests.removedByProject_addsToOtherProjects_withInheritance()
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
		:select('workspaces', 'Workspace1')
		:select('projects', 'Project2', State.INHERIT)

	test.isEqual({ 'VALUE1', 'VALUE2', 'VALUE3' }, project2:get('defines'))
end


function StateRemoveTests.removedByProject_addsToOtherProjects_withNoInheritance()
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
		:select('workspaces', 'Workspace1')
		:select('projects', 'Project2')

	test.isEqual({ 'VALUE2' }, project2:get('defines'))
end


function StateRemoveTests.removedByConfig_addsToOtherConfigs_withInheritance()
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
		:select('workspaces', 'Workspace1')
		:select('projects', 'Project1', State.INHERIT)
		:select('configurations', 'Release', State.INHERIT)

	test.isEqual({ 'VALUE1', 'VALUE2', 'VALUE3' }, releaseCfg:get('defines'))
end


function StateRemoveTests.removedByConfig_addsToOtherConfigs_withNoInheritance()
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
		:select('workspaces', 'Workspace1')
		:select('projects', 'Project1')
		:select('configurations', 'Release')

	test.isEqual({ 'VALUE2' }, releaseCfg:get('defines'))
end

function StateRemoveTests.removedByConfig_addsToOtherConfigs_withMixedInheritance()
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
		:select('workspaces', 'Workspace1')
		:select('projects', 'Project1')
		:select('configurations', 'Release', State.INHER)

	test.isEqual({ 'VALUE2' }, releaseCfg:get('defines'))
end


---
-- Values removed by a broader scope should follow the same rules
---

function StateRemoveTests.removeByProject_fromConfig_withInheritance()
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

	local cfg = State.new(store)
		:select('workspaces', 'Workspace1')
		:select('configurations', 'Debug', State.INHERIT)

	test.isEqual({ 'DEBUG1', 'DEBUG3' }, cfg:get('defines'))
end


function StateRemoveTests.removeByProject_fromConfig_withNoInheritance()
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

	local cfg = State.new(store)
		:select('workspaces', 'Workspace1')
		:select('configurations', 'Debug')

	test.isEqual({ 'DEBUG1', 'DEBUG3' }, cfg:get('defines'))
end
