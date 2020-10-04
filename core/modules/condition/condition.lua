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

local Condition = declareType('Condition')

local OP_TEST = 'TEST'
local OP_AND = 'AND'
local OP_OR = 'OR'
local OP_NOT = 'NOT'

local ALLOW_NIL = true


---
-- Create a new Condition instance.
--
-- @param clauses
--    A table of field-pattern pairs representing the clauses of the condition.
-- @return
--    A new Condition instance representing the specified clauses.
---

function Condition.new(clauses)
	local self = instantiateType(Condition, {
		_fieldsTested = {},
		_rootTest = nil
	})

	local ok, result = pcall(function()
		return Condition._parseCondition(self, clauses)
	end)

	if not ok then
		error(result, 2)
	end

	self._rootTest = result
	return self
end


---
-- Returns `true` if every clause in the condition has a passing value in `values`,
-- or no value (`nil`). Returns `false` if `values` contains an non-nil value which
-- fails one of the clauses.
---

function Condition.isNotFailedBy(self, values)
	local ok, result = pcall(function()
		return Condition._test(self._rootTest, values, ALLOW_NIL)
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
		return Condition._test(self._rootTest, values)
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
	local rootTest = table.joinArrays(outer._rootTest, inner._rootTest)
	rootTest._op = OP_AND

	return instantiateType(Condition, {
		_fieldsTested = fieldsTested,
		_rootTest = rootTest
	})
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

function Condition._parseCondition(self, clauses)
	local tests = { _op = OP_AND }

	for key, pattern in pairs(clauses) do
		clause = Condition._parseClause(self, nil, key, pattern)
		table.insert(tests, clause)
	end

	return tests
end


function Condition._parseClause(self, defaultFieldName, fieldName, pattern)
	-- if clause was specified as an array value rather than a key-value pair, parse out the target field name
	if type(fieldName) ~= 'string' then
		-- canonically "not" should be specified after the field name but not everyone thinks that way; move it for them
		local shouldNegate = false
		if string.startsWith(pattern, 'not ') then
			pattern = string.sub(pattern, 5)
			shouldNegate = true
		end
		return Condition._parseFieldName(self, defaultFieldName, pattern, shouldNegate)
	end

	local parts = string.split(pattern, ' or ', true)
	if #parts > 1 then
		return Condition._parseOrOperators(self, fieldName or defaultFieldName, parts)
	end

	if string.startsWith(pattern, 'not ') then
		return Condition._parseNotOperator(self, defaultFieldName, fieldName, pattern)
	end

	-- we've reduced it to a simple 'key=value' test
	self._fieldsTested[fieldName] = true
	return { _op = OP_TEST, fieldName, pattern }
end


function Condition._parseFieldName(self, defaultFieldName, pattern, shouldNegate)
	local parts = string.split(pattern, ':', true, 1)
	if #parts > 1 then
		fieldName = parts[1]
		pattern = parts[2]
	else
		fieldName = defaultFieldName
	end

	if fieldName == nil then
		error('No field name specified for condition "' .. pattern .. "'", 0)
	end

	if shouldNegate then
		pattern = 'not ' .. pattern
	end

	return Condition._parseClause(self, nil, fieldName, pattern)
end


function Condition._parseNotOperator(self, defaultFieldName, fieldName, pattern)
	pattern = string.sub(pattern, 5)
	return {
		_op = OP_NOT,
		Condition._parseClause(self, defaultFieldName, fieldName, pattern)
	}
end


function Condition._parseOrOperators(self, defaultFieldName, patterns)
	local tests = { _op = OP_OR }

	for i = 1, #patterns do
		local test = Condition._parseClause(self, defaultFieldName, nil, patterns[i])
		table.insert(tests, test)
	end

	return tests
end


---
-- Evaluate a test tree.
---

function Condition._test(operation, values, allowNil)
	local result

	local op = operation._op

	if op == OP_TEST then

		local fieldName = operation[1]
		local pattern = operation[2]
		local testValue = values[fieldName]

		if not testValue then
			result = allowNil
		else
			local field = Field.get(fieldName)
			result = Field.contains(field, testValue, pattern, true)
		end

	elseif op == OP_AND then

		for i = 1, #operation do
			if not Condition._test(operation[i], values, allowNil) then
				return false
			end
		end
		return true

	elseif op == OP_NOT then

		return not Condition._test(operation[1], values, allowNil)

	elseif op == OP_OR then

		for i = 1, #operation do
			if Condition._test(operation[i], values, allowNil) then
				return true
			end
		end
		return false

	end

	return result
end


return Condition
