local StringTests = test.declare('StringTests')

-- string.contains() --

function StringTests.contains_returnsTrue_onMatch()
	test.isTrue(string.contains('a.b', '.'))
end

function StringTests.contains_returnsFalse_onNoMatch()
	test.isFalse(string.contains('abc', '.'))
end


-- string.findLast() --

function StringTests.findLast_returnsCorrectIndex_onMatch()
	test.isEqual(5, string.findLast('abcabc', 'b'))
end

function StringTests.findLast_returnsNil_onNoMatch()
	test.isNil(string.findLast('abcabc', 'x'))
end


-- string.patternFromWildcards() --

function StringTests.patternFromWildcards_leavesUnchanged_onNoWildcards()
	test.isEqual('abcd', string.patternFromWildcards('abcd'))
end

function StringTests.patternFromWildcards_replacesStarWithLuaPattern()
	test.isEqual('ab.*', string.patternFromWildcards('ab*'))
end


-- string.split() --

function StringTests.split_returnsUnchanged_onNoMatch()
	test.isEqual({ 'aaa' }, string.split('aaa', '/', true))
end

function StringTests.split_splitsCorrectly_onPlainText()
	test.isEqual({ 'aaa', 'bbb', 'ccc' }, string.split('aaa/bbb/ccc', '/', true))
end


-- string.startsWith() --

function StringTests.startsWith_isTrue_onMatch()
	test.isTrue(string.startsWith('Abcdef', 'Abc'))
end

function StringTests.startsWith_isFalse_onMismatch()
	test.isFalse(string.startsWith('Abcdef', 'ghi'))
end

function StringTests.startsWith_isFalse_onLongerNeedle()
	test.isFalse(string.startsWith('Abc', 'Abcdef'))
end

function StringTests.startsWith_isFalse_onEmptyHaystack()
	test.isFalse(string.startsWith('', 'Abc'))
end

function StringTests.startsWith_isTrue_onEmptyNeedle()
	test.isTrue(string.startsWith('Abcdef', ''))
end
