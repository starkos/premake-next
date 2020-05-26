---
-- The Store provides storage for all of the configuration settings pushed in by the
-- user scripts, and methods to query those settings for use by the actions and
-- exporters.
---

local Field = require('field')

local Condition = require('condition')
local Query = require('query')

local Store = {}


local _metatable = { -- set up ':' style calling
	__index = function(self, key)
		return Store[key]
	end
}


---
-- Construct a new Store.
--
-- @return
--    A new Store instance.
---

function Store.new()
	local store = setmetatable({
		_conditions = {},
		_currentCondition = nil,
		_blocks = {},
		_currentBlock = nil
	}, _metatable)

	Store.pushCondition(store, {})
	return store
end


---
-- Pushes a new configuration condition onto the condition stack.
--
-- @param clauses
--    A collection of key-value pairs of conditional clauses,
--    ex. `{ workspaces='Workspace1', configurations='Debug' }`
---

function Store.pushCondition(self, clauses)
	local condition = Condition.register(clauses)

	local conditions = self._conditions
	if #conditions > 0 then
		local outerCondition = conditions[#conditions]
		condition = Condition.merge(outerCondition, condition)
	end

	table.insert(conditions, condition)
	self._currentCondition = condition
	self._currentBlock = nil
	return self
end


---
-- Pops a configuration condition from the top of the condition stack.
---

function Store.popCondition(self)
	local conditions = self._conditions
	table.remove(conditions)
	self._currentCondition = conditions[#conditions]
	self._currentBlock = nil
	return self
end


---
-- Start a store query. Given a table describing the current execution
-- environment (system, current action, options, etc.) returns a Query
-- representing the "global" scope.
--
-- @param env
--    The query environment. A collection of key-value pairs representing
--    the current execution environment.
-- @returns
--    A Query object encapsulating the global configuration scope for the
--    provided execution environment.
---

function Store.query(self, env)
	local query = Query.newFromStore(self._blocks, env)
	-- Query.evaluate(query)
	return query
end


---
-- Adds a value or values to the currently active configuration.
---

function Store.addValue(self, fieldName, value)
	Store._applyValueOperation(self, Query.ADDING, fieldName, value)
	return self
end


---
-- Flags one or more configured values for removal from the currently
-- active configuration.
---

function Store.removeValue(self, fieldName, value)
	Store._applyValueOperation(self, Query.REMOVING, fieldName, value)
	return self
end


function Store._applyValueOperation(self, operation, fieldName, value)
	local block = self._currentBlock

	if block == nil or block._operation ~= operation then
		block = {
			_condition = self._currentCondition,
			_operation = operation
		}
		table.insert(self._blocks, block)
		self._currentBlock = block
	end

	local currentValue = block[fieldName]

	local field = Field.get(fieldName)
	block[fieldName] = Field.mergeValues(field, currentValue, value)
end


return Store
