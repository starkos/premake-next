local Condition = require('condition')

local ConditionFailedByTests = test.declare('ConditionFailedByTests', 'condition')


---
-- `isNotFailedBy` should return true if all clauses have a matching value, or no
-- value (`nil`). Should return false if any value fails a clause.
---

function ConditionFailedByTests.isNotFailedBy_isTrue_onValueMatch()
	local c = Condition.new({ kind = 'StaticLibrary' })
	test.isTrue(c:isNotFailedBy({ kind = 'StaticLibrary' }))
end


function ConditionFailedByTests.isNotFailedBy_isTrue_onValueMissing()
	local c = Condition.new({ kind = 'StaticLibrary' })
	test.isTrue(c:isNotFailedBy({}))
end

function ConditionFailedByTests.isNotFailedBy_isFalse_onValueMismatch()
	local c = Condition.new({ kind = 'StaticLibrary' })
	test.isFalse(c:isNotFailedBy({ kind = 'ConsoleApplication' }))
end
