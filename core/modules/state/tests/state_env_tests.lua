---
-- Tests basic querying against environmental values with no scoping or inheritance.
---

local Store = require('store')
local State = require('state')

local StateEnvTests = test.declare('StateEnvTests', 'state')

local store

function StateEnvTests.setup()
	store = Store.new()
end


---
-- `get()` should be able to retrieve values when no conditions are involved.
---

function StateEnvTests.get_returnsSimpleValue_onNoConditions()
	store:addValue('kind', 'StaticLibrary')
	test.isEqual('StaticLibrary', State.new(store):get('kind'))
end


function StateEnvTests.get_returnsCollectionValue_onGlobalScope()
	store:addValue('defines', { 'A', 'B' })
	test.isEqual({ 'A', 'B' }, State.new(store):get('defines'))
end


---
-- `get()` should return a default "empty" value for fields which have not been
-- set: `nil` for simple fields, and an empty collection for collection fields.
---

function StateEnvTests.get_returnsNil_onUnsetString()
	test.isNil(State.new(store):get('kind'))
end


function StateEnvTests.get_returnsEmptyList_onUnsetList()
	test.isEqual({}, State.new(store):get('defines'))
end


---
-- Values placed behind a condition should not be returned if condition is not met.
---

function StateEnvTests.get_returnsNil_onUnmetStringCondition()
	store
		:pushCondition({ system = 'Windows' })
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	test.isNil(State.new(store):get('kind'))
end


function StateEnvTests.get_returnsNil_onUnmetListCondition()
	store
		:pushCondition({ defines = 'X' })
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	test.isNil(State.new(store):get('kind'))
end


---
-- Values behind a condition should be available once that condition is met.
---

function StateEnvTests.get_returnsValue_onStringConditionMet()
	store
		:pushCondition({ system = 'Windows' })
		:addValue('kind', 'StaticLibrary')
		:popCondition()

	local state = State.new(store, { system = 'Windows' })
	test.isEqual('StaticLibrary', state:get('kind'))
end


function StateEnvTests.get_returnsValue_onListConditionMet()
	store
		:pushCondition{ defines = 'X' }
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	local state = State.new(store, { defines = 'X' })
	test.isEqual('SharedLibrary', state:get('kind'))
end


---
-- It should be possible to test for values that haven't been set yet (i.e. setting up
-- target type specific settings at the global or workspace level, when `kind` isn't set
-- until projects are configured later).
---

function StateEnvTests.canEvaluateBlocksOutOfOrder()
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
