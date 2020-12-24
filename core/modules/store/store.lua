---
-- The Store provides storage for all of the configuration settings pushed in by the
-- user scripts, and methods to query those settings for use by the actions and
-- exporters.
---

local Block = require('block')
local Condition = require('condition')
local Stack = require('stack')

local Store = declareType('Store')


---
-- Adds new block to the end of the store's list of blocks.
---

local function _appendBlock(self, operation)
	local block = table.last(self._blocks)
	local condition = Stack.top(self._conditions)

	-- Check to see if the current block was actually used. If not, reuse it
	if block ~= nil and block.operation == Block.NONE then
		block.operation = operation
		block.condition = condition
	else
		block = Block.new(operation, condition)
		table.insert(self._blocks, block)
	end

	return block
end


---
-- Stores values into a block.
--
-- @param operation
--    One of ADD or REMOVE, indicating whether the intended operation is to store new values
--    in the settings (e.g. `defines 'A'`) or remove existing values (`removeDefines 'A'`).
-- @param field
--    The field being stored.
-- @param value
--    The value to be added to the field's contents.
---

function _applyValueOperation(self, operation, field, value)
	local block = table.last(self._blocks)

	-- If the current block is targeting the same operation (ADD or REMOVE), I can just push
	-- this new value into it. If it is a different operation I have to create a new block
	if block.operation ~= operation and block.operation ~= Block.NONE then
		block = _appendBlock(self, operation)
	end

	block.operation = operation
	Block.store(block, field, value)
end


---
-- Construct a new Store.
--
-- @return
--    A new Store instance.
---

function Store.new()
	-- if new fields are added here, update `snapshot()` and `restore()` too
	local newStore = instantiateType(Store, {
		_conditions = Stack.new({ Condition.new(_EMPTY) }),
		_blocks = {}
	})

	_appendBlock(newStore, _EMPTY, Block.NONE)

	return newStore
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
	_appendBlock(self, Block.NONE)

	return self
end


---
-- Pops a configuration condition from the top of the condition stack.
---

function Store.popCondition(self)
	Stack.pop(self._conditions)
	_appendBlock(self, Block.NONE)
	return self
end


---
-- Adds a value or values to the current configuration.
---

function Store.addValue(self, field, value)
	_applyValueOperation(self, Block.ADD, field, value)
	return self
end


---
-- Flags one or more values for removal from the current configuration.
---

function Store.removeValue(self, field, value)
	_applyValueOperation(self, Block.REMOVE, field, value)
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


return Store
