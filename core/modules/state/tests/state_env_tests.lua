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
-- Simplest sanity check: get a value with no conditions involved
---

function StateEnvTests.returnsString_onNoConditions()
	store:addValue('kind', 'StaticLibrary')
	test.isEqual('StaticLibrary', State.new(store):get('kind'))
end


function StateEnvTests.returnsList_onNoConditions()
	store:addValue('defines', { 'A', 'B' })
	test.isEqual({ 'A', 'B' }, State.new(store):get('defines'))
end


---
-- `get()` should return a default "empty" value for fields which have not been
-- set: `nil` for simple fields, and an empty collection for collection fields.
---

function StateEnvTests.returnsNil_onUnsetString()
	test.isNil(State.new(store):get('kind'))
end


function StateEnvTests.returnsEmptyList_onUnsetList()
	test.isEqual({}, State.new(store):get('defines'))
end


---
-- Values placed behind a top-level condition should not be returned if condition is not met.
---

function StateEnvTests.returnsNil_onUnmetStringCondition()
	store
		:pushCondition({ system = 'Windows' })
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	local state = State.new(store)
	test.isNil(state:get('kind'))
end


function StateEnvTests.returnsNil_onUnmetListCondition()
	store
		:pushCondition({ defines = 'X' })
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	local state = State.new(store)
	test.isNil(state:get('kind'))
end


---
-- Values behind a top-level condition should be available once condition is met
---

function StateEnvTests.returnsValue_onStringConditionMet()
	store
		:pushCondition({ system = 'Windows' })
		:addValue('kind', 'StaticLibrary')
		:popCondition()

	local state = State.new(store, { system = 'Windows' })
	test.isEqual('StaticLibrary', state:get('kind'))
end


---
-- Values which are a stored into a block should also be used to meet criteria
---

function StateEnvTests.returnsValue_whenStringValueSet()
	store
		:addValue('system', 'Windows')
		:pushCondition{ system = 'Windows' }
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	local state = State.new(store)
	test.isEqual('SharedLibrary', state:get('kind'))
end

function StateEnvTests.returnsValue_whenListValueSet()
	store
		:addValue('defines', { 'X', 'Y', 'Z' })
		:pushCondition{ defines = 'Y' }
		:addValue('kind', 'SharedLibrary')
		:popCondition()

	local state = State.new(store)
	test.isEqual('SharedLibrary', state:get('kind'))
end



---
-- When conditions are nested, clauses should be combined. All clauses must be met to pass
---

function StateEnvTests.returnsAllValues_onNestedConditionMet()
	store
		:pushCondition({ system = 'Windows' })
		:addValue('defines', 'SYSTEM')

		:pushCondition({ action = 'vstudio' })
		:addValue('defines', 'ACTION')

	local state = State.new(store, { system = 'Windows', action = 'vstudio' })
	test.isEqual({ 'SYSTEM', 'ACTION' }, state:get('defines'))
end


function StateEnvTests.excludesNested_onOuterConditionNotMet()
	store
		:pushCondition({ system = 'Windows' })
		:addValue('defines', 'SYSTEM')

		:pushCondition({ action = 'vstudio' })
		:addValue('defines', 'ACTION')

	local state = State.new(store, { system = 'Linux', action = 'vstudio' })
	test.isEqual({}, state:get('defines'))
end


function StateEnvTests.excludesNested_oInnerConditionMet()
	store
		:pushCondition({ system = 'Windows' })
		:addValue('defines', 'SYSTEM')

		:pushCondition({ action = 'vstudio' })
		:addValue('defines', 'ACTION')

	local state = State.new(store, { system = 'Windows', action = 'gmake' })
	test.isEqual({ 'SYSTEM' }, state:get('defines'))
end


---
-- It should be possible to test for values that haven't been set yet (i.e. setting up
-- target type specific settings at the global or workspace level, when `kind` isn't set
-- until projects are configured later). List values should still be returned in the
-- order in which the blocks were initially created.
---

function StateEnvTests.canEvaluateBlocksOutOfOrder()
	store
		:pushCondition({ kind = 'StaticLibrary' })
		:addValue('defines', 'KIND')
		:popCondition()

		:pushCondition({ action = 'vstudio' })
		:addValue('kind', 'StaticLibrary')
		:addValue('defines', 'ACTION')
		:popCondition()

	local state = State.new(store, { action = 'vstudio' })
	test.isEqual({ 'KIND', 'ACTION' }, state:get('defines'))
end
