---
-- A query processes selections against a store. Create new queries
-- by calling `Store.query()`.
---

local Condition = require('condition')
local Field = require('field')


local EMPTY = {}

local UNKNOWN = 'UNKNOWN'
local ADD = 'ADD'
local REMOVE = 'REMOVE'
local IGNORE = 'IGNORE'
local OUT_OF_SCOPE = 'OUT_OF_SCOPE'

local Query = declareType('Query')

Query.ADD = ADD
Query.REMOVE = REMOVE


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
	return instantiateType(Query, {
		_sourceBlocks = blocks,   -- The list of blocks to be queried,;received from a store, should be considered immutable
		_enabledBlocks = nil,     -- Once `evaluate()` is called, the list of blocks which apply to this query
		_outer = nil,
		_env = Query._normalize(env),
		_localScope = EMPTY,
		_fullScope = EMPTY,
		_requiredScope = EMPTY,
		_isInheriting = false
	})
end


function Query._with(self, newValues)
	local mergedValues = table.mergeKeys(self, newValues)
	return instantiateType(Query, mergedValues)
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
	local result = Field.defaultValue(field)

	local blocks = self._enabledBlocks
	for i = 1, #blocks do
		local block = blocks[i]
		local blockValue = block.source[fieldName]

		if blockValue then
			if block.localOp == ADD then
				result = Field.mergeValues(field, result, blockValue)
			else
				result = Field.removeValues(field, result, blockValue)
			end
		end
	end

	return result
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
	-- To evaluate a query, it is necessary to build up two different states. The "local" state
	-- contains the results for this query and take into account the chosen scope (workspace, project,
	-- file configuration, etc.). The "global" state represents all of the settings that _could_
	-- appear in this query, if inheritance were enabled all the way up to the global scope (global,
	-- workspace, project, configuration, ...). This global state is needed to correctly interpret
	-- requests to remove values.

	-- "Operations" refer to the intention of a block, one of ADD, REMOVE, IGNORE (the block doesn't
	-- apply to this query), and UNKNOWN (the block hasn't been evaluated yet).

	-- The source blocks are reused by multiple queries so can't be modified; set up my
	-- own view into the source blocks with results relevant to this query.

	local blocks = {}
	local sourceBlocks = self._sourceBlocks
	for i = 1, #sourceBlocks do
		table.insert(blocks, {
			source = sourceBlocks[i],
			localOp = UNKNOWN,
			globalOp = UNKNOWN
		})
	end

	-- These hold the values that have been accumulated so far, and are used to test conditionals

	local localValues = table.mergeKeys(self._env)
	local globalValues = table.mergeKeys(self._env)

	-- Keep iterating over the list of blocks until all have been processed. Each time new values
	-- are added and removed, any blocks that had been previously skipped over need to be rechecked
	-- to see if they have come into scope as a result of the new state.

	local function _DEBUG(...)
		-- test.print(...)
	end

	local i = 1
	while i <= #blocks do
		local block = blocks[i]
		local sourceBlock = block.source
		local globalOp = block.globalOp

		if globalOp ~= UNKNOWN and globalOp ~= IGNORE then
			i = i + 1
		else

			_DEBUG('------------------------------------------------')
			_DEBUG('INDEX:', i)
			_DEBUG('BLOCK:', table.toString(block))
			_DEBUG('LOCAL VALUES:', table.toString(localValues))
			_DEBUG('GLOBAL VALUES:', table.toString(globalValues))
			_DEBUG('LOCAL SCOPE:', table.toString(self._localScope))
			_DEBUG('REQ SCOPE:', table.toString(self._requiredScope))
			_DEBUG('FULL SCOPE:', table.toString(self._fullScope))

			local localOp, globalOp = Query._testBlock(self, sourceBlock, localValues, globalValues)

			_DEBUG('localOp:', localOp)
			_DEBUG('globalOp:', globalOp)

			block.localOp = localOp
			block.globalOp = globalOp

			if localOp == ADD and sourceBlock._operation == REMOVE then
				-- This is a remove block which would have already removed the values higher up in the
				-- configuration tree (ex. the workspace). But the conditions surrounding the remove don't
				-- apply to this specific query, so we now need to add those values back in. This happens
				-- when a value is removed from one of several siblings; ex. if a symbol is removed from
				-- 'Project1', 'Project2' and 'Project3' should still have that symbol set. Can't just
				-- blindly assume all of the removed values were actually present at the parent though;
				-- check the global state and only add back values which are really there.

				block.localOp = OUT_OF_SCOPE  -- don't want to remove, will insert additions instead
				_DEBUG('replacing remove with add')

				local newSourceBlockWithAdditions = {}

				for fieldName, removePatterns in pairs(sourceBlock) do
					if Field.exists(fieldName) then
						local field = Field.get(fieldName)

						-- TODO: Need a `_fetch(fieldName, blockList)` here once `evaluate()` is reworked to only pull
						-- the values required by the conditionals. For now, it's always fetching every field so I can
						-- assume the values are all there.
						local currentGlobalValues = globalValues[fieldName]

						local _, removedValues = Field.removeValues(field, currentGlobalValues, removePatterns)

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
							newSourceBlockWithAdditions[fieldName] = addedValues
						end
					end
				end

				table.insert(blocks, i, {
					source = newSourceBlockWithAdditions,
					localOp = ADD,
					globalOp = OUT_OF_SCOPE -- don't want these additions included in global results
				})

				Query._mergeBlockWithValues(self, newSourceBlockWithAdditions, localValues, self._fullScope, ADD)
			end

			-- Apply a "normal" add or remove block to the accumlated values

			if localOp == sourceBlock._operation then
				Query._mergeBlockWithValues(self, sourceBlock, localValues, self._fullScope, localOp)
			end

			-- Apply an add/remove block to the inherited results
			if globalOp == sourceBlock._operation then
				Query._mergeBlockWithValues(self, sourceBlock, globalValues, EMPTY, globalOp)
			end

			_DEBUG('local after:', table.toString(localValues))
			_DEBUG('global after:', table.toString(globalValues))

			if globalOp ~= IGNORE then
				i = 1  -- something was changed, retest previously ignored blocks
			else
				i = i + 1
			end
		end
	end

	-- Weed out all of the blocks that don't apply to this query for faster fetches later

	local enabledBlocks = {}

	for i = 1, #blocks do
		local block = blocks[i]
		local localOp = block.localOp

		if localOp == ADD or localOp == REMOVE then
			table.insert(enabledBlocks, block)
		end
	end

	self._enabledBlocks = enabledBlocks
end


function Query._testBlock(self, block, localValues, globalValues)
	local condition = block._condition
	local operation = block._operation

	-- If the condition fails against the inherited state then this block isn't intended for us
	if not Condition.isSatisfiedBy(condition, globalValues) then
		return IGNORE, IGNORE
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

	return IGNORE, operation
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
