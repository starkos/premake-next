---
-- Conditions represent the "where" tests for a configuration block. If a condition
-- evaluates to `true` then the data contained in the configuration block should be
-- applied.
--
-- Conditions are made up clauses. This condition contains two clauses:
--
--     { system='Windows', kind='SharedLib' }
---

local Field = require('field')

local Condition = {}

local OP_TEST = 1
local OP_AND = 2
local OP_OR = 3
local OP_NOT = 4

local TEST_SCOPE = 1
local TEST_STRICT = 2
local TEST_LOOSE = 3


local _metatable = { -- set up ':' style calling
	__index = function(self, key)
		return Condition[key]
	end
}


---
-- Register and possible create a condition.
--
-- @param clauses
--    A table of field-pattern pairs representing the clauses of the condition.
-- @return
--    A Condition representing the provided clauses.
---

function Condition.register(clauses)
	local fieldsTested = {}

	local ok, result = pcall(function()
		return Condition._parseUserClauses(clauses, fieldsTested)
	end)

	if not ok then
		error(result, 2)
	end

	return setmetatable({
		_fieldsTested = fieldsTested,
		_test = result
	}, _metatable)
end


---
-- Returns true if each clause is satisfied by the filtering values, or if
-- no filtering value is provided (`nil`) for that clause. It should return
-- false if the filtering values contain a conflicting value for the clause.
---

function Condition.isLooseMatch(self, values)
	local ok, result = pcall(function()
		return Condition._test(self._test, values, TEST_LOOSE)
	end)

	if not ok then
		error(result, 2)
	end

	return result
end


---
-- Returns true is all values in the provided scope have a corresponding
-- clause in the condition which is satisfied by the scope value.
---

function Condition.isScopeMatch(self, scope)
	local fieldsTested = self._fieldsTested
	local test = self._test

	for scopeKey, scopeValue in pairs(scope) do
		if not fieldsTested[scopeKey] then
			return false
		end
	end

	local ok, result = pcall(function()
		return Condition._test(test, scope, TEST_SCOPE)
	end)

	if not ok then
		error(result, 2)
	end

	return result
end


---
-- Returns true if all clauses are satisfied by provided filtering values.
---

function Condition.isStrictMatch(self, values)
	local ok, result = pcall(function()
		return Condition._test(self._test, values, TEST_STRICT)
	end)

	if not ok then
		error(result, 2)
	end

	return result
end


---
-- Merges conditions by AND-ing all of the clauses together.
---

function Condition.merge(outer, inner)
	local fieldsTested = table.mergeKeys(outer._fieldsTested, inner._fieldsTested)
	local test = table.joinArrays(outer._test, inner._test)
	test._op = OP_AND

	return setmetatable({
		_fieldsTested = fieldsTested,
		_test = test
	}, _metatable)
end


---
-- Parse incoming user clauses received from the project scripts into a tree
-- of logical operations.
---

function Condition._parseUserClauses(clauses, fieldsTested)
	local clause

	local result = { _op = OP_AND }

	for field, pattern in pairs(clauses) do
		field, clause = Condition._parseUserClause(field, pattern, fieldsTested)
		table.insert(result, clause)
	end

	return result
end


function Condition._parseUserClause(fieldName, pattern, fieldsTested)
	fieldsTested[fieldName] = true
	return field, { _op = OP_TEST, fieldName, pattern }
end


---
-- Evaluate a test tree.
---

function Condition._test(operation, values, kind)
	if operation._op == OP_TEST then

		local fieldName = operation[1]
		local pattern = operation[2]
		local testValue = values[fieldName]

		if not testValue then
			return (kind ~= TEST_STRICT)
		else
			local field = Field.get(fieldName)
			return Field.matchesPattern(field, testValue, pattern)
		end

	elseif operation._op == OP_AND then

		for i = 1, #operation do
			if not Condition._test(operation[i], values, kind) then
				return false
			end
		end
		return true

	end
end


return Condition
