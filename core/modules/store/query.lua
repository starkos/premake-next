---
-- A query processes selections against a store. Create new queries
-- by calling `Store.query()`.
---

local Condition = require('condition')
local Field = require('field')

local Query = {}

Query.ADDING = 1
Query.REMOVING = 2


local _metatable = { -- set up ':' style calling
	__index = function(self, key)
		return Query[key]
	end
}


function Query._new(sourceBlocks, outerQuery, scope, env, shouldInheritValues)
	return setmetatable({
		_sourceBlocks = sourceBlocks,
		_outerQuery = outerQuery,
		_scope = scope,
		_env = env,
		_isInheritingValues = shouldInheritValues
	}, _metatable)
end


---
-- Create a Query from a store's list of configuration blocks. In normal use
-- you should not call this directly, use `Store.query()` instead.
--
-- @param blocks
--    The store's array of configuration blocks.
-- @param env
--    The query environment, a collection of key-value pairs used to satisfy
--    block conditions.
---

function Query.newFromStore(blocks, env)
	local normalizedEnv = Query._normalizeEnv(env)
	return Query._new(blocks, nil, {}, normalizedEnv)
end


---
-- Fetch a value from the query.
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
	local env = self._env

	local field = Field.get(fieldName)

	local value
	if self._isInheritingValues then
		value = Query.fetch(self._outerQuery, fieldName)
	else
		value = Field.defaultValue(field)
	end

	local blocks = self._sourceBlocks
	for i = 1, #blocks do
		local block = blocks[i]
		local condition = block._condition

		if block._operation == Query.ADDING then
			if Condition.isScopeMatch(condition, self._scope) and Condition.isStrictMatch(condition, env) then
				local blockValue = block[fieldName]
				if blockValue then
					value = Field.mergeValues(field, value, blockValue)
				end
			end
		else
			if Condition.isLooseMatch(condition, env) then
				local patternsToRemove = block[fieldName]
				if patternsToRemove then
					value = Field.removeValues(field, value, patternsToRemove)
				end
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
	if self._outerQuery ~= nil then
		return Query._new(self._sourceBlocks, self._outerQuery, self._scope, self._env, true)
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
	local normalizedScope = Query._normalizeEnv(scope)
	local normalizedEnv = Query._normalizeEnv(self._env, scope, extraEnv or {})
	return Query._new(self._sourceBlocks, self, normalizedScope, normalizedEnv)
end


---
-- Merge and normalize one or more query environment tables.
--
-- "Normalizing" means converting one-off string values into collections
-- for collection fields, e.g. turning `{ projects = 'Project1' }` into
-- `{ projects = { 'Project1`' } }`.
---

function Query._normalizeEnv(...)
	local result = {}

	for i = 1, select('#', ...) do
		local env = select(i, ...)
		for fieldName, value in pairs(env) do
			local field = Field.get(fieldName)
			result[fieldName] = Field.mergeValues(field, result[fieldName], value)
		end
	end

	return result
end


return Query
