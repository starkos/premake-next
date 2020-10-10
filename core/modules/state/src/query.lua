local Block = require('block')
local Condition = require('condition')
local Field = require('field')

local Query = {}

local UNKNOWN = 'UNKNOWN'
local ADD = 'ADD'
local REMOVE = 'REMOVE'
local IGNORE = 'IGNORE'
local OUT_OF_SCOPE = 'OUT_OF_SCOPE'


function Query.new(blocks)
	return {
		_sourceBlocks = blocks,
		_outerQuery = nil,
		_localScope = _EMPTY,
		_fullScope = _EMPTY,
		_requiredScope = _EMPTY
	}
end


---
-- Clone and return a new query, overlaying the provided new values.
---

function Query._with(self, newValues)
	return table.mergeKeys(self, newValues)
end


function Query.evaluate(self, env)
	-- To evaluate a query, it is necessary to build up two different states. The "local" state
	-- contains the results for this query and takes into account the chosen scope (workspace, project,
	-- file configuration, etc.). The "global" state represents all of the settings that _could_
	-- appear in this query, if inheritance were enabled all the way up to the global scope (global,
	-- workspace, project, configuration, ...). This global state is needed to correctly interpret
	-- requests to remove values.

	-- "Operations" refer to the intention of a block, one of ADD, REMOVE, IGNORE (the block doesn't
	-- apply to this query), and UNKNOWN (the block hasn't been evaluated yet).

	-- The source blocks are reused by multiple queries so can't be modified; set up my
	-- own view into the source blocks with results relevant to this query.

	local sourceBlocks = self._sourceBlocks
	local evalBlocks = {}

	for i = 1, #sourceBlocks do
		table.insert(evalBlocks, {
			sourceBlock = sourceBlocks[i],
			localOp = UNKNOWN,
			globalOp = UNKNOWN
		})
	end

	-- These hold the values that have been accumulated so far, and are used to test conditionals

	local localValues = table.mergeKeys(env)
	local globalValues = table.mergeKeys(env)

	-- Keep iterating over the list of blocks until all have been processed. Each time new values
	-- are added and removed, any blocks that had been previously skipped over need to be rechecked
	-- to see if they have come into scope as a result of the new state.

	-- local function _DEBUG(...)
	-- 	test.print(...)
	-- end

	local i = 1
	while i <= #evalBlocks do
		local evalBlock = evalBlocks[i]
		local globalOp = evalBlock.globalOp

		local sourceBlock = evalBlock.sourceBlock
		local sourceOp = Block.operation(sourceBlock)

		if globalOp ~= UNKNOWN and globalOp ~= IGNORE then
			i = i + 1
		else

			-- _DEBUG('------------------------------------------------')
			-- _DEBUG('INDEX:', i)
			-- _DEBUG('BLOCK:', table.toString(block))
			-- _DEBUG('LOCAL VALUES:', table.toString(localValues))
			-- _DEBUG('GLOBAL VALUES:', table.toString(globalValues))
			-- _DEBUG('LOCAL SCOPE:', table.toString(self._localScope))
			-- _DEBUG('REQ SCOPE:', table.toString(self._requiredScope))
			-- _DEBUG('FULL SCOPE:', table.toString(self._fullScope))

			local localOp, globalOp = Query._testBlock(self, sourceBlock, sourceOp, localValues, globalValues)

			-- _DEBUG('localOp:', localOp)
			-- _DEBUG('globalOp:', globalOp)

			evalBlock.localOp = localOp
			evalBlock.globalOp = globalOp

			if localOp == ADD and sourceOp == REMOVE then
				-- This is a remove block which would have already removed the values higher up in the
				-- configuration tree (ex. the workspace). But the conditions surrounding the remove don't
				-- apply to this specific query, so we now need to add those values back in. This happens
				-- when a value is removed from one of several siblings; ex. if a symbol is removed from
				-- 'Project1', but 'Project2' and 'Project3' should still have that symbol set. Can't just
				-- blindly assume all of the removed values were actually present at the parent though;
				-- check the global state and only add back values which are really there.

				evalBlock.localOp = OUT_OF_SCOPE

				local newSourceBlockWithAdditions = Block.new(Block.ADD, _EMPTY, Block.baseDir(sourceBlock))

				for fieldName, removePatterns in pairs(sourceBlock) do
					if Field.exists(fieldName) then
						local field = Field.get(fieldName)

						-- run the remove patterns from the block against the currently set values and see what we get
						local currentGlobalValues = globalValues[fieldName]
						local _, removedValues = Field.removeValues(field, currentGlobalValues, removePatterns)

						-- add back any removed values that aren't already in the local state
						local valuesToAdd = {}

						local currentLocalValues = localValues[fieldName] or {}
						for i = 1, #removedValues do
							local value = removedValues[i]
							-- in this case, don't want to add duplicates even if the field would otherwise allow it
							if not Field.contains(field, currentLocalValues, value) then
								table.insert(valuesToAdd, value)
							end
						end

						if #valuesToAdd > 0 then
							newSourceBlockWithAdditions[fieldName] = valuesToAdd
						end
					end
				end

				table.insert(evalBlocks, i, {
					sourceBlock = newSourceBlockWithAdditions,
					localOp = ADD,
					globalOp = OUT_OF_SCOPE -- don't want these additions included in global results
				})

				Query._mergeBlockWithValues(self, newSourceBlockWithAdditions, localValues, self._fullScope, ADD)
			end

			-- Apply a "normal" add or remove block to the accumlated values
			if localOp == sourceOp then
				Query._mergeBlockWithValues(self, sourceBlock, localValues, self._fullScope, localOp)
			end

			-- Apply an add/remove block to the inherited results
			if globalOp == sourceOp then
				Query._mergeBlockWithValues(self, sourceBlock, globalValues, _EMPTY, globalOp)
			end

			-- _DEBUG('local after:', table.toString(localValues))
			-- _DEBUG('global after:', table.toString(globalValues))

			if globalOp ~= IGNORE then
				i = 1  -- something was changed, retest previously ignored blocks
			else
				i = i + 1
			end
		end
	end

	-- Weed out all of the blocks that don't apply to this query for faster fetches later

	local enabledBlocks = {}

	for i = 1, #evalBlocks do
		local evalBlock = evalBlocks[i]
		local localOp = evalBlock.localOp

		if localOp == ADD or localOp == REMOVE then
			table.insert(enabledBlocks, evalBlock.sourceBlock)
		end
	end

	return enabledBlocks
end


function Query._testBlock(self, block, operation, localValues, globalValues)
	local condition = Block.condition(block)

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


---
-- Merges the values contained by a configuration block with an accumated state table.
---

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


function Query.select(self, scope)
	return Query._with(self, {
		_outerQuery = self,
		_localScope = scope,
		_fullScope = table.mergeKeys(self._fullScope, scope),
		_requiredScope = table.mergeKeys(self._requiredScope, scope)
	})
end


function Query.withInheritance(self)
	if self._outerQuery ~= nil then
		return Query._with(self, {
			_requiredScope = self._outerQuery._requiredScope
		})
	else
		return self
	end
end


return Query
