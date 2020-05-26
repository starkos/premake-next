local Condition = require('../condition')

local ConditionTests = test.declare('condition')


---
-- `register()` should return an object and not crash.
---

function ConditionTests.register_returnsObject()
	test.isNotNil(Condition.register({}))
end


---
-- `isScopeMatch()` should return true if the condition contains a clause
-- for each key in the scope, and if that clause is satified by the
-- corresponding scope value.
---

function ConditionTests.isScopeMatch_isTrue_onNoScope()
	local cond = Condition.register({ projects = 'Project1' })
	test.isTrue(cond:isScopeMatch({}))
end


function ConditionTests.isScopeMatch_isTrue_onClauseMet()
	local cond = Condition.register({ projects = 'Project1' })
	test.isTrue(cond:isScopeMatch({ projects = {'Project1'} }))
end


function ConditionTests.isScopeMatch_isFalse_onMissingClause()
	local cond = Condition.register({ projects = 'Project1' })
	test.isFalse(cond:isScopeMatch({ workspaces = {'Workspace1'} }))
end


function ConditionTests.isScopeMatch_isFalse_onClauseNotMet()
	local cond = Condition.register({ projects = 'Project1' })
	test.isFalse(cond:isScopeMatch({ projects = {'Project2'} }))
end


---
-- `isStrictMatch()` should return true if all clauses of the condition
-- have been satisfied by the provided values.
---

function ConditionTests.isStrictMatch_isTrue_onSingleValueMatch()
	local cond = Condition.register({ kind = 'StaticLibrary' })
	test.isTrue(cond:isStrictMatch({ kind = 'StaticLibrary' }))
end


---
-- `isStrictMatch()` should return false if any clause of the condition
-- is missing or not satisfied by the provided values.
---

function ConditionTests.isStrictMatch_isFalse_onValueMissing()
	local cond = Condition.register({ kind = 'StaticLibrary' })
	test.isFalse(cond:isStrictMatch({}))
end


function ConditionTests.isStrictMatch_isFalse_onValueMismatch()
	local cond = Condition.register({ kind = 'StaticLibrary' })
	test.isFalse(cond:isStrictMatch({ kind = 'ConsoleApplication' }))
end


function ConditionTests.isStrictMatch_isTrue_onValueMatch()
	local cond = Condition.register({ kind = 'StaticLibrary' })
	test.isTrue(cond:isStrictMatch({ kind = 'StaticLibrary' }))
end


---
-- `isLooseMatch()` should return true if each clause is satisfied by the
-- provided values, or if no value is provided (`nil`) for that clause. It
-- should return false if the provided values contain a conflicting value
-- for the clause.
---

function ConditionTests.isLooseMatch_isTrue_onValueMissing()
	local cond = Condition.register({ kind = 'StaticLibrary' })
	test.isTrue(cond:isLooseMatch({}))
end


function ConditionTests.isLooseMatch_isFalse_onValueMismatch()
	local cond = Condition.register({ kind = 'StaticLibrary' })
	test.isFalse(cond:isLooseMatch({ kind = 'ConsoleApplication' }))
end


function ConditionTests.isLooseMatch_isTrue_onValueMatch()
	local cond = Condition.register({ kind = 'StaticLibrary' })
	test.isTrue(cond:isLooseMatch({ kind = 'StaticLibrary' }))
end


---
-- Test parsing of user specified conditions
---

function ConditionTests.singleClause_asKeyValue_withStringField()
	local cond = Condition.register({ system = 'Windows' })
	test.isTrue(cond:isStrictMatch({ system = 'Windows' }))
	test.isFalse(cond:isStrictMatch({ system = 'MacOS' }))
end
