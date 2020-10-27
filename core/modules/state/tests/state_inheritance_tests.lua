local Store = require('store')
local State = require('state')

local StateInheritanceTests = test.declare('StateInheritanceTests', 'state')


local store

function StateInheritanceTests.setup()
	store = Store.new()
	:addValue('defines', 'GLOBAL')

	:pushCondition({ workspaces = 'Workspace1' })
	:addValue('projects', 'Project1')
	:addValue('defines', 'WORKSPACE')

	:pushCondition({ projects = 'Project1' })
	:addValue('configurations', 'Debug')
	:addValue('defines', 'PROJECT')

	:pushCondition({ configurations = 'Debug' })
	:addValue('defines', 'CONFIG')
end


---
-- When inheritance is enabled, should include values from the immediate outer scope
---

function StateInheritanceTests.workspace_canInheritGlobal()
	local state = State.new(store)
		:select('workspaces', 'Workspace1', State.INHERIT)

	test.isEqual({ 'GLOBAL', 'WORKSPACE' }, state:get('defines'))
end

function StateInheritanceTests.project_canInheritWorkspace()
	local state = State.new(store)
		:select('workspaces', 'Workspace1')
		:select('projects', 'Project1', State.INHERIT)

	test.isEqual({ 'WORKSPACE', 'PROJECT' }, state:get('defines'))
end

function StateInheritanceTests.config_canInheritProject()
	local state = State.new(store)
		:select('workspaces', 'Workspace1')
		:select('projects', 'Project1')
		:select('configurations', 'Debug', State.INHERIT)

	test.isEqual({ 'PROJECT', 'CONFIG' }, state:get('defines'))
end


---
-- If a scope is not inheriting, should not receive outer values even if outer
-- scope has inheritance enabled.
---

function StateInheritanceTests.project_notInheriting()
	local state = State.new(store)
		:select('workspaces', 'Workspace1', State.INHERIT)
		:select('projects', 'Project1')

	test.isEqual({ 'PROJECT' }, state:get('defines'))
end

function StateInheritanceTests.config_notInheriting()
	local state = State.new(store)
		:select('workspaces', 'Workspace1', State.INHERIT)
		:select('projects', 'Project1', State.INHERIT)
		:select('configurations', 'Debug')

	test.isEqual({ 'CONFIG' }, state:get('defines'))
end


---
-- If outer scope is also inheriting, inherited values should be included
---

function StateInheritanceTests.project_whenOuterInheriting()
	local state = State.new(store)
		:select('workspaces', 'Workspace1', State.INHERIT)
		:select('projects', 'Project1', State.INHERIT)

	test.isEqual({ 'GLOBAL', 'WORKSPACE', 'PROJECT' }, state:get('defines'))
end

function StateInheritanceTests.config_whenOuterInheriting()
	local state = State.new(store)
		:select('workspaces', 'Workspace1', State.INHERIT)
		:select('projects', 'Project1', State.INHERIT)
		:select('configurations', 'Debug', State.INHERIT)

	test.isEqual({ 'GLOBAL', 'WORKSPACE', 'PROJECT', 'CONFIG' }, state:get('defines'))
end
