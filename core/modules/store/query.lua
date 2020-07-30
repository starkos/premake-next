---
-- A query processes selections against a store. Create new queries
-- by calling `Store.query()`.
---

local Condition = require('condition')
local Field = require('field')


local EMPTY = {}

local ADD = 1
local REMOVE = 2
local IGNORE = 3


local Query = {}

Query.ADD = ADD
Query.REMOVE = REMOVE


local _metatable = { -- set up ':' style calling
	__index = function(self, key)
		return Query[key]
	end
}


local function _DEBUG(...)
	-- test.print(...)
end


---
-- Create a Query from a list of configuration blocks. In normal use you would
-- not call this directly, use `Store.query()` instead.
--
-- @param blocks
--    An array of configuration blocks.
-- @param env
--    The query environment, a collection of key-value pairs used to satisfy
--    block conditions.
---

function Query.new(blocks, env)
	return setmetatable({
		-- TODO: explain what these are
		_outer = nil,
		_env = Query._normalize(env),
		_sourceBlocks = blocks,
		_enabledBlocks = nil,
		_localScope = EMPTY,
		_fullScope = EMPTY,
		_requiredScope = EMPTY,
		_isInheriting = false,
		_values = nil
	}, _metatable)
end


function Query._with(self, newValues)
	local newQuery = table.mergeKeys(self, newValues)
	return setmetatable(newQuery, _metatable)
end


function Query.newStorageBlock(operation, condition)
	return {
		_operation = operation,
		_condition = condition
	}
end


---
-- Fetch a value from a query instance.
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
--    The name of the field to fetch.
-- @returns
--    The value of the field as determined by any current filters, if set.
--    If the field was not set, returns the default value defined for the
--    field's kind.
---

function Query.fetch(self, fieldName)
	if self._enabledBlocks == nil then
		Query._evaluate(self)
	end

	local field = Field.get(fieldName)
	local value = Field.defaultValue(field)

	local blocks = self._enabledBlocks
	for i = 1, #blocks do
		local block = blocks[i]
		local blockValue = block._values[fieldName]

		if blockValue then
			if block._operation == ADD then
				value = Field.mergeValues(field, value, blockValue)
			else
				value = Field.removeValues(field, value, blockValue)
			end
		end
	end

	return value
end


---
-- Returns a new Query instance with value inheritance enabled. The query scope
-- and environment are the same as the query instance on which it was called.
--
-- When inheritance is enabled, values from the immediate out scope (the "parent"
-- query, on which `select()` was called) are included in fetches.
---

function Query.inheritValues(self)
	if self._outer ~= nil then
		return Query._with(self, {
			_requiredScope = self._outer._requiredScope,
			_isInheriting = true
		})
	else
		return self
	end
end


---
-- Select an "inner" scope from an "outer" one, ex. a specific project from
-- a workspace.
--
-- @param scope
--    Key-value pair(s) representing the new scope, ex. `{ project = 'Project1' }`.
-- @param extraEnv
--    An option table of additional key-value pairs to add to the query environment.
-- @returns
--    A new Query instance representing the inner scope.
---

function Query.select(self, scope, extraEnv)
	return Query._with(self, {
		_outer = self,
		_env = Query._normalize(self._env, scope, extraEnv or EMPTY),
		_localScope = Query._normalize(scope),
		_fullScope = Query._normalize(self._fullScope, scope),
		_requiredScope = Query._normalize(self._requiredScope, scope)
	})
end


---
-- Evaluate the query.
--
-- Preprocess the list of storage blocks to determine which ones are a
-- match to the query parameters. Must be called before any values are
-- fetched.
---

function Query._evaluate(self)
	-- To evaluate a query, actually need to build up two different states. The "local" state contains
	-- the results for this query. The "inherited" state collects all the results for this query, as
	-- well as any values that could be inherited from other scopes higher up in the configuration tree
	-- (e.g. a workspace or project). This inherited state is needed in order to figure out what to do
	-- with removed values. Hopefully the comments below will help explain.

	-- "Blocks" holds a list of all settings blocks that apply to this query; when `fetch()` is called it
	-- can quickly iterate this list knowing that all of the conditions have already been checked and passed

	-- "Values" holds the values that are accumulated during the process of building the block lists.

	local localBlocks = {}
	local localValues = table.mergeKeys(self._env)

	local inheritedBlocks = {}
	local inheritedValues = table.mergeKeys(self._env)

	self._enabledBlocks = localBlocks
	self._values = localValues

	local blocks = self._sourceBlocks
	for i = 1, #blocks do
		local block = blocks[i]

		_DEBUG('------------------------------------------------')
		_DEBUG('BLOCK:', table.toString(block))
		_DEBUG('LOCAL VALUES:', table.toString(localValues))
		_DEBUG('ALL VALUES:', table.toString(inheritedValues))


		_DEBUG('REQ SCOPE:', table.toString(self._requiredScope))
		_DEBUG('FULL SCOPE:', table.toString(self._fullScope))
		_DEBUG('LOCAL SCOPE:', table.toString(self._localScope))

		local localOperation, inheritedOperation = Query._testBlock(self, block, localValues, inheritedValues)

		_DEBUG('local op:', localOperation)
		_DEBUG('inherit op:', inheritedOperation)

		if localOperation == ADD and block._operation == REMOVE then
			-- Encountered a remove block which would have already removed the values higher up in the
			-- configuration tree (ex. the workspace). But the conditions surrounding the remove don't
			-- apply to this specific query, so we now need to add those values back in. This happens
			-- when a value is removed from one of several siblings; if a symbol is removed from 'Project1',
			-- 'Project2' and 'Project3' should still have that symbol set.

			-- Can't just blindly assume all of the removed values were actually present at the parent
			-- though; check the inherited state and only add back values which are really there.

			local additionsBlock = {}

			for fieldName, removePatterns in pairs(block) do
				if Field.exists(fieldName) then
					local field = Field.get(fieldName)

					-- TODO: Need a `_fetch(fieldName, blockList)` here once `evaluate()` is reworked to only pull
					-- the values which are required by the conditionals. For now, it's always fetching every field
					-- so I can assume the values are all there.
					local currentInheritedValues = inheritedValues[fieldName]

					local _, removedValues = Field.removeValues(field, currentInheritedValues, removePatterns)

					local currentLocalValues = localValues[fieldName] or {} -- use `_fetch()` here too

					local addedValues = {}

					for i = 1, #removedValues do
						local value = removedValues[i]
						-- in this case, don't want to add duplicates even if the field would otherwise allow it
						if not Field.contains(field, currentLocalValues, value) then
							table.insert(addedValues, value)
						end
					end

					if #addedValues > 0 then
						additionsBlock[fieldName] = addedValues
					end
				end
			end

			table.insert(localBlocks, {
				_operation = ADD,
				_values = additionsBlock
			})

			Query._mergeBlockWithValues(self, additionsBlock, localValues, self._fullScope, ADD)
		end

		-- Apply an add/remove block to the query results
		if localOperation == block._operation then
			Query._mergeBlockWithValues(self, block, localValues, self._fullScope, localOperation)
			table.insert(localBlocks, {
				_operation = localOperation,
				_values = block
			})
		end

		-- Apply an add/remove block to the inherited results
		if inheritedOperation ~= nil then
			Query._mergeBlockWithValues(self, block, inheritedValues, EMPTY, inheritedOperation)
			table.insert(inheritedBlocks, {
				_operation = localOperation,
				_values = block
			})
		end

		_DEBUG('local after:', table.toString(localValues))
		_DEBUG('all after:', table.toString(inheritedValues))
	end
end


function Query._testBlock(self, block, localValues, inheritedValues)


	local condition = block._condition
	local operation = block._operation

	-- If the condition fails against the inherited state then this block isn't intended for us
	if not Condition.isSatisfiedBy(condition, inheritedValues) then
		return Query.IGNORE, Query.IGNORE
	end

	if operation == ADD then

		local meetsScopeRequirement = Condition.testsAllKeys(condition, self._localScope) or Condition.testsAllKeys(condition, self._requiredScope)
		if meetsScopeRequirement and Condition.isSatisfiedBy(condition, localValues) then
			return ADD, operation
		end

	else -- operation == REMOVE

		-- If condition matches current local state, block should be applied to results
		if Condition.isSatisfiedBy(condition, localValues) then
			return REMOVE, operation
		end

		-- If the local state is simply missing values listed in the condition, and doesn't
		-- specifically fail any of the clauses, that means that this remove block applies to
		-- something "below" us in the workspace, and the block should be applied here
		if Condition.isNotFailedBy(condition, localValues) then
			return REMOVE, operation
		end

		-- I've confirmed that a) this block applies to the target workspace, b) the value was
		-- marked for removal somewhere else in the configuration tree, but was removed higher
		-- up because we're only allow to add values at export time, and c) I'm on a different
		-- branch in the configuration tree than the one where the value was marked for removal
		-- so it's time to add it back. Get all that? :)
		return ADD, operation

	end

	return Query.IGNORE, operation
end


function Query._mergeBlockWithValues(self, block, values, scope, operation)
	for fieldName, value in pairs(block) do
		if Field.exists(fieldName) and not scope[fieldName] then
			local field = Field.get(fieldName)
			if operation == ADD then
				values[fieldName] = Field.mergeValues(field, values[fieldName], value)
			else
				values[fieldName] = Field.removeValues(field, values[fieldName], value)
			end
		end
	end
end


---
-- Merge and normalize one or more query environment tables.
--
-- "Normalizing" means converting one-off string values into the correct collection type,
-- e.g. turning `{ projects = 'Project1' }` into `{ projects = { 'Project1' } }`.
---

function Query._normalize(...)
	local result = {}

	for i = 1, select('#', ...) do
		local env = select(i, ...)
		if env ~= nil then
			for fieldName, value in pairs(env) do
				local field = Field.get(fieldName)
				result[fieldName] = Field.mergeValues(field, result[fieldName], value)
			end
		end
	end

	return result
end


return Query
