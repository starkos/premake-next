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

local ALLOW_NIL = true


local _metatable = { -- set up ':' style calling
	__index = function(self, key)
		return Condition[key]
	end
}


---
-- Create a new Condition instance.
--
-- @param clauses
--    A table of field-pattern pairs representing the clauses of the condition.
-- @return
--    A new Condition instance representing the specified clauses.
---

function Condition.new(clauses)
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
-- Returns `true` if every clause in the condition has a passing value in `values`,
-- or no value (`nil`). Returns `false` if `values` contains an non-nil value which
-- fails one of the clauses.
---

function Condition.isNotFailedBy(self, values)
	local ok, result = pcall(function()
		return Condition._test(self._test, values, ALLOW_NIL)
	end)

	if not ok then
		error(result, 2)
	end

	return result
end


---
-- Returns `true` if every clause in the condition has a passing non-nil value in `values`.
---

function Condition.isSatisfiedBy(self, values)
	local ok, result = pcall(function()
		return Condition._test(self._test, values)
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
-- Checks to see if a condition contains clauses to test all of the keys in the
-- provided list of fields. If any key is present in `fields` which can't be matched
-- to a corresponding clause in the condition, the test fails and returns `false`.
---

function Condition.testsAllKeys(self, fields)
	for fieldName in pairs(fields) do
		if not self._fieldsTested[fieldName] then
			return false
		end
	end
	return true
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

function Condition._test(operation, values, allowNil)
	local result

	if operation._op == OP_TEST then

		local fieldName = operation[1]
		local pattern = operation[2]
		local testValue = values[fieldName]

		if not testValue then
			result = allowNil
		else
			local field = Field.get(fieldName)
			result = Field.contains(field, testValue, pattern)
		end

	elseif operation._op == OP_AND then

		for i = 1, #operation do
			if not Condition._test(operation[i], values, allowNil) then
				return false
			end
		end
		return true

	end

	return result
end


return Condition
