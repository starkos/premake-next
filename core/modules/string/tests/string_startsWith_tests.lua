local StringStartsWithTests = test.declare('StringStartsWithTests', 'string')


function StringStartsWithTests.startsWith_isTrue_onMatch()
	test.isTrue(string.startsWith('Abcdef', 'Abc'))
end

function StringStartsWithTests.startsWith_isFalse_onMismatch()
	test.isFalse(string.startsWith('Abcdef', 'ghi'))
end

function StringStartsWithTests.startsWith_isFalse_onLongerNeedle()
	test.isFalse(string.startsWith('Abc', 'Abcdef'))
end

function StringStartsWithTests.startsWith_isFalse_onEmptyHaystack()
	test.isFalse(string.startsWith('', 'Abc'))
end

function StringStartsWithTests.startsWith_isTrue_onEmptyNeedle()
	test.isTrue(string.startsWith('Abcdef', ''))
end
