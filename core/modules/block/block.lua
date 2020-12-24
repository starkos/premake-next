---
-- Blocks store a chunk of project configuration, tied to a condition indicating under what
-- circumstances the configuration should be applied, and an operator indicating whether the
-- values contained by the block are to be added or removed from the final result.
--
-- For performance, this module is just a thin wrapper over Lua tables. It does not define
-- a format `Block` type.
---

local Field = require('field')

local Block = {}

Block.NONE = 'NONE'
Block.ADD = 'ADD'
Block.REMOVE = 'REMOVE'


function Block.new(operation, condition, baseDir)
	return {
		_operation = operation,
		_condition = condition,
		_baseDir = baseDir or _SCRIPT_DIR
	}
end


---
-- Does this block support storing or removing values? To enforce order of operations, each
-- blocks either contains values to be added to the state, or removed. Blocks can then be
-- combined in order to get the target state.
--
-- @param operation
--    The target operation, one of `Block.ADD` or `Block.REMOVE`.
---

function Block.acceptsOperation(self, operation)
	return (self ~= nil and self._operation == operation)
end


function Block.baseDir(self)
	return self._baseDir
end


function Block.condition(self)
	return self._condition
end


function Block.operation(self)
	return self._operation
end


function Block.store(self, fieldName, value)
	local field = Field.get(fieldName)
	self[fieldName] = Field.mergeValues(field, self[fieldName], value)
end


return Block
