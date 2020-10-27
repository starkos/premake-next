---
-- Query and access configuration settings which meet a certain set of criteria.
--
-- "Environment" is a collection of key-value pairs which describes the current
-- operating environment. This includes things like the host OS, the target action,
-- etc. These values are used to satisfy criteria.
--
-- "Scope" is a singular key-value pair. Like environment, it is also used to
-- satisfy criteria. But it also limits results to those blocks which specifically
-- test for that scope. So if scope is set to the project 'Project1', only blocks
-- which specifically test for `projects = "Project1"` will be considered.
---

local Block = require('block')
local Condition = require('condition')
local Field = require('field')
local Store = require('store')

local State = declareType('State')

local Query = doFile('./src/query.lua')

State.INHERIT = 'inherit'
State.NO_INHERIT = 'no-inherit'

local _UNSET = {}


-- Enable dot-indexing of field values
State.__index = function(self, key)
	return State[key] or State.get(self, key)
end


local function _new(values)
	return instantiateType(State, table.mergeKeys(values, {
		_blocks = _UNSET,
		_withInheritance = _UNSET
	}))
end


---
-- Creates a new "root" state, given a configuration store and the initial environment values.
--
-- @param store
--    A `Store` containing the configuration to be queried.
-- @param env
--    The initial query environment, a collection of key-value pairs used to satisfy block conditions.
---

function State.new(store, env)
	return _new({
		_query = Query.new(Store.blocks(store)),
		_env = env or _EMPTY
	})
end


---
-- Retrieve a value from a state.
--
-- **Values returned from this method should be considered immutable!**
--
-- I don't have a way to enforce that (yet), so you'll just have to be on
-- your best behavior. If you change a value returned from this method,
-- you may be changing it for all future calls as well. Make copies before
-- making changes!
--
-- (We don't want to be making copies here because that would be a big
-- performance hit, and most times it isn't needed.)
--
-- @param fieldName
--    The name of the field to retrieve.
-- @returns
--    The value of the field as determined by any current filters, if set.
--    If the field was not set, returns the default value defined for the
--    field's kind.
---

function State.get(self, fieldName)
	if self._blocks == _UNSET then
		self._blocks = Query.evaluate(self._query, self._env)
		self._unsetValues = {}
	end

	local value = rawget(self, fieldName) or self._unsetValues[fieldName]

	if value == nil then
		value = self._env[fieldName]

		if value == nil and Field.exists(fieldName) then
			value = State._buildValue(self, fieldName)
		end

		if value == nil then
			self._unsetValues[fieldName] = _UNSET
		else
			self[fieldName] = value
		end
	end

	if value ~= _UNSET then
		return value
	end
end


function State._buildValue(self, fieldName)
	local field = Field.get(fieldName)
	local result = Field.defaultValue(field)

	local blocks = self._blocks
	for i = 1, #blocks do
		local block = blocks[i]
		local blockValue = block[fieldName]

		if blockValue then
			if Block.operation(block) == Block.ADD then
				result = Field.mergeValues(field, result, blockValue)
			else
				result = Field.removeValues(field, result, blockValue)
			end
		end
	end

	return result
end


---
-- Selects a new state out of an existing one, e.g. a specific project from
-- a workspace.
--
-- @param scope
--    The scope being selected, ex. "workspaces" or "projects".
-- @param identifier
--    The scope identifier, ex. "MyWorkspace" or "MyProject".
-- @param inherit
--    One of `State.INHERIT` or `State.NO_INHERIT`. Controls whether values should be inherited from
--    the source state.
-- @returns
--    A new State instance representing the inner scope.
---

function State.select(self, scope, identifier, inherit)
	local fullScope = { [scope] = { identifier }}

	local newState = _new({
		_query = Query.select(self._query, fullScope),
		_env = table.mergeKeys(self._env, fullScope)
	})

	if inherit == State.INHERIT then
		newState = State.withInheritance(newState)
	end

	return newState
end


---
-- Returns a new state with value inheritance enabled. The query scope and environment
-- are the same as the state instance on which `withInheritance()` is called.
--
-- When inheritance is enabled, values from the immediate outer scope (the "parent"
-- query, on which `select()` was called) are included in the results.
---

function State.withInheritance(self)
	if self._withInheritance == _UNSET then
		if self._isInheriting then
			self._withInheritance = self
		else
			self._withInheritance = _new({
				_query = Query.withInheritance(self._query),
				_env = self._env,
				_isInheriting = true,
				_withoutInheritance = self
			})
		end
	end
	return self._withInheritance
end



---
-- Returns a new state with value inheritance disabled. The query scope and environment
-- are the same as the state instance on which `withoutInheritance()` is called.
--
-- When inheritance is disabled, values from the immediate outer scope (the "parent"
-- query, on which `select()` was called) are not included in the results.
---

function State.withoutInheritance(self)
	return self._withoutInheritance or self
end


return State
