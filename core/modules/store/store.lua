---
-- The Store provides storage for all of the configuration settings pushed in by the
-- user scripts, and methods to query those settings for use by the actions and
-- exporters.
---

local Store = declareType('Store')

local Block = require('block')
local Condition = require('condition')
local Stack = require('stack')


---
-- Construct a new Store.
--
-- @return
--    A new Store instance.
---

function Store.new()
	-- if new fields are added here, update `snapshot()` and `restore()` too
	return instantiateType(Store, {
		_conditions = Stack.new({ Condition.new(_EMPTY) }),
		_blocks = {}
	})
end


---
-- Return the list of configuration blocks contained by the store.
---

function Store.blocks(self)
	return self._blocks
end


---
-- Pushes a new configuration condition onto the condition stack.
--
-- @param clauses
--    A collection of key-value pairs of conditional clauses,
--    ex. `{ workspaces='Workspace1', configurations='Debug' }`
---

function Store.pushCondition(self, clauses)
	local conditions = self._conditions

	local condition = Condition.new(clauses)

	local outerCondition = Stack.top(conditions)
	if outerCondition ~= nil then
		condition = Condition.merge(outerCondition, condition)
	end

	Stack.push(conditions, condition)
	Store._newBlock(self, Block.ADD)

	return self
end


---
-- Pops a configuration condition from the top of the condition stack.
---

function Store.popCondition(self)
	Stack.pop(self._conditions)
	Store._newBlock(self, Block.ADD)
	return self
end


---
-- Adds a value or values to the current configuration.
---

function Store.addValue(self, fieldName, value)
	Store._applyValueOperation(self, Block.ADD, fieldName, value)
	return self
end


---
-- Flags one or more values for removal from the current configuration.
---

function Store.removeValue(self, fieldName, value)
	Store._applyValueOperation(self, Block.REMOVE, fieldName, value)
	return self
end


---
-- Make a note of the current store state, so it can be rolled back later.
---

function Store.snapshot(self)
	local snapshot = {
		_conditions = self._conditions,
		_blocks = self._blocks
	}

	self._conditions = table.shallowCopy(self._conditions)
	self._blocks = table.shallowCopy(self._blocks)
	Store.pushCondition(self, _EMPTY)

	return snapshot
end


---
-- Roll back the store state to a previous snapshot.
---

function Store.rollback(self, snapshot)
	self._conditions = table.shallowCopy(snapshot._conditions)
	self._blocks = table.shallowCopy(snapshot._blocks)
end


---
-- Store values to be added or removed from a configuration, creating a new block if needed.
---

function Store._applyValueOperation(self, operation, fieldName, value)
	local block = table.last(self._blocks)

	if not Block.acceptsOperation(block, operation) then
		block = Store._newBlock(self, operation)
	end

	Block.store(block, fieldName, value)
end


---
-- Add a new block to the block list and return it.
---

function Store._newBlock(self, operation)
	local condition = Stack.top(self._conditions)
	local block = Block.new(operation, condition, _SCRIPT_DIR)
	table.insert(self._blocks, block)
	return block
end


return Store
