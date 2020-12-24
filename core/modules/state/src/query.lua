local Block = require('block')
local Condition = require('condition')
local Field = require('field')
local Store = require('store')

local Query = {}

-- result values for  block tests
local UNKNOWN = Block.NONE
local ADD = Block.ADD
local REMOVE = Block.REMOVE
local IGNORE = 'IGNORE'
local OUT_OF_SCOPE = 'OUT_OF_SCOPE'


-- Enabling the debug statements is a big performance hit.
-- local function _debug(...) if _LOG_PREMAKE_QUERIES then print(...) end end


---
-- Apply add/remove operations from a block to a value collection. This gets called
-- for each enabled block to accumulate a complete state.
--
-- TODO: Should only accumulate fields that are actually used by block conditions; the
--    other fields are just being ignored. Pull fields for removes too? Or just fetch
--    those on demand if/when needed?
---

local function _accumulateValuesFromBlock(values, block, operation)
	for fieldName, value in pairs(block) do
		if Field.exists(fieldName) then
			local field = Field.get(fieldName)
			if operation == ADD then
				values[fieldName] = Field.mergeValues(field, values[fieldName], value)
			else
				values[fieldName] = Field.removeValues(field, values[fieldName], value)
			end
		end
	end
	return values
end


---
-- Evaluate a state query.
--
-- @returns
--    A list of state blocks which apply to the state's scopes and initial values.
---

function Query.evaluate(state)
	-- In order to properly handle removed values (see `state_remove_tests.lua`), evaluation must
	-- accumulate two parallels states: a "target" state, or the one requested by the caller, and
	-- a "global" state which includes all values that could possibly be inherited by the target
	-- scope, if all levels of inheritance were enabled. When a request is made to remove a value,
	-- we check this global state to see if the value has actually been set, and make the appropriate
	-- corrections to ensure the change gets applied correctly.
	local targetValues = table.shallowCopy(state._initialValues)
	local globalValues = table.shallowCopy(state._initialValues)

	local sourceBlocks = state._sourceBlocks
	local targetScopes = state._targetScopes
	local globalScopes = state._globalScopes

	-- _debug('TARGET SCOPES:', table.toString(targetScopes))
	-- _debug('GLOBAL SCOPES:', table.toString(globalScopes))
	-- _debug('INITIAL VALUES:', table.toString(targetValues)

	-- The list of incoming source blocks is shared and shouldn't be modified. Set up a parallel
	-- list to keep track of which blocks we've tested, and the per-block test results.

	local blockResults = {}

	for i = 1, #sourceBlocks do
		table.insert(blockResults, {
			targetOperation = UNKNOWN,
			globalOperation = UNKNOWN,
			data = sourceBlocks[i]
		})
	end

	-- Set up to iterate the list of blocks multiple times. Each time new values are
	-- added or removed from the target state, any blocks that had been previously skipped
	-- over need to be rechecked to see if they have come into scope as a result.
	-- TODO: Tracking which blocks depend on which fields might be an optimization opportunity

	local i = 1

	while i <= #blockResults do
		local blockResult = blockResults[i]
		local sourceBlock = blockResult.data

		local targetOperation = blockResult.targetOperation
		local globalOperation = blockResult.globalOperation

		-- if we've already made a decision on this block, skip over it
		if globalOperation ~= UNKNOWN then
			i = i + 1
		else
			local blockCondition = Block.condition(sourceBlock)
			local blockOperation = Block.operation(sourceBlock)

			-- _debug('----------------------------------------------------')
			-- _debug('BLOCK #:', i)
			-- _debug('BLOCK OPER:', blockOperation)
			-- _debug('BLOCK EXPR:', table.toString(blockCondition))
			-- _debug('TARGET VALUES:', table.toString(targetValues))
			-- _debug('GLOBAL VALUES:', table.toString(globalValues))

			local function _testBlock(sourceBlock, blockCondition, blockOperation, globalScopes, globalValues, targetScopes, targetValues)
				if blockOperation == ADD then
					if not Condition.matchesScopeAndValues(blockCondition, globalValues, globalScopes) then
						return UNKNOWN, UNKNOWN
					end

					if not Condition.matchesScopeAndValues(blockCondition, targetValues, targetScopes) then
						return ADD, UNKNOWN
					end

					return ADD, ADD
				end

				if blockOperation == REMOVE then

					-- Try to eliminate this block by comparing it to the current accumulated global state. Here
					-- I don't care about strict scoping, and I don't care if some of the values being tested by
					-- the block condition are missing (`NIL_MATCHES_ANY`). I'm only concerned if a value contained
					-- in my global set of values *conflicts* with something being requested by the scope.
					--
					--   'configurations:Debug' == 'Debug' is a match
					--   'configurations:Debug' == nil is a match
					--   'configurations:Debug' == 'Release' is a fail
					--
					-- If the match *fails*, that means that this block will never apply to this particular scope
					-- hierarchy, so I can reject it outright.

					if not Condition.matchesValues(blockCondition, globalValues, globalValues, Condition.NIL_MATCHES_ANY) then
						return UNKNOWN, UNKNOWN
					end

					-- If this block matches any scope in my hierarchy then this remove applies to me
					local i = Condition.matchesScopeAndValues(blockCondition, targetValues, targetScopes, Condition.NIL_MATCHES_ANY)
					if i then
						if i <= #state._localScopes then
							-- exact scope match
							return REMOVE, REMOVE
						else
							-- inherited scope match
							return REMOVE, IGNORE
						end
					end

					-- So...this block passed the "soft" match against the global values, but failed against my
					-- specific scoping. That means it is intended for a sibling of the target scope: a different
					-- project, configuration, etc. from the one that is currently being built. In order to keep
					-- things additive, that means I find myself in the uncomfortable position of having to *add*
					-- the value in, rather than remove...see notes in test suite and (eventually) the README.

					return REMOVE, ADD
				end

				-- _debug('Unhandled block operation')
				return UNKNOWN, UNKNOWN
			end

			globalOperation, targetOperation = _testBlock(sourceBlock, blockCondition, blockOperation, globalScopes, globalValues, targetScopes, targetValues)
			-- _debug('GLOBAL RESULT:', globalOperation)
			-- _debug('TARGET RESULT:', targetOperation)

			if targetOperation == ADD and globalOperation == REMOVE then
				-- I've hit the sibling of a scope which removed values. To stay additive, the values were actually
				-- removed by my container. Now I'm in the awkward position of needing to add them back in. Can't be
				-- just a simple add though: have to make sure I only add in values that might have actually been set.
				-- Might have to deal with wildcard matches. Need to synthesize a new ADD block for this. Start by
				-- excluding the current remove block from the target results.

				blockResult.targetOperation = OUT_OF_SCOPE

				-- Then build a new block and insert values that would be removed by the container

				local newAddBlock = Block.new(Block.ADD, _EMPTY, Block.baseDir(sourceBlock))

				for fieldName, removePatterns in pairs(sourceBlock) do
					if Field.exists(fieldName) then
						local field = Field.get(fieldName)

						-- Run the remove patterns from the block against the currently set values and see what we get;
						-- add back any removed values that aren't already in the local state.
						local valuesToAdd = {}
						local _, removedValues = Field.removeValues(field, globalValues[fieldName], removePatterns)
						local currentTargetValues = targetValues[fieldName] or {}
						for i = 1, #removedValues do
							local value = removedValues[i]
							-- in this case, don't want to add duplicates even if the field would otherwise allow it
							if not Field.matches(field, currentTargetValues, value) then
								table.insert(valuesToAdd, value)
							end
						end
						if #valuesToAdd > 0 then
							newAddBlock[fieldName] = valuesToAdd
						end
					end
				end

				-- Insert the new block into my result list

				table.insert(blockResults, i, {
					targetOperation = ADD,
					globalOperation = OUT_OF_SCOPE,
					data = newAddBlock
				})

				targetValues = _accumulateValuesFromBlock(targetValues, newAddBlock, ADD)

			elseif targetOperation ~= UNKNOWN then
				blockResult.targetOperation = targetOperation
				targetValues = _accumulateValuesFromBlock(targetValues, sourceBlock, targetOperation)
			end

			if globalOperation ~= UNKNOWN then
				blockResult.globalOperation = globalOperation -- TODO: do I need to store this? Once values have been processed at the global scope I'm done?
				globalValues = _accumulateValuesFromBlock(globalValues, sourceBlock, globalOperation)
			end

			-- If accumulated state changed rerun previously skipped blocks to see if they should now be enabled
			if globalOperation ~= UNKNOWN then
				-- _debug('STATE CHANGED, rerunning skipped blocks')
				i = 1
			else
				i = i + 1
			end
		end
	end

	return blockResults
end


return Query
