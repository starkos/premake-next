local suite = test.declare('string')

-- string.findLast() --

function suite.findLast_returnsCorrectIndex_onMatch()
	test.isEqual(5, string.findLast('abcabc', 'b'))
end

function suite.findLast_returnsNil_onNoMatch()
	test.isNil(string.findLast('abcabc', 'x'))
end


-- string.patternFromWildcards() --

function suite.patternFromWildcards_leavesUnchanged_onNoWildcards()
	test.isEqual('abcd', string.patternFromWildcards('abcd'))
end

function suite.patternFromWildcards_replacesStarWithLuaPattern()
	test.isEqual('ab.*', string.patternFromWildcards('ab*'))
end


-- string.split() --

function suite.split_returnsUnchanged_onNoMatch()
	test.isEqual({ 'aaa' }, string.split('aaa', '/', true))
end

function suite.split_splitsCorrectly_onPlainText()
	test.isEqual({ 'aaa', 'bbb', 'ccc' }, string.split('aaa/bbb/ccc', '/', true))
end


-- string.startsWith() --

function suite.startsWith_isTrue_onMatch()
	test.isTrue(string.startsWith('Abcdef', 'Abc'))
end

function suite.startsWith_isFalse_onMismatch()
	test.isFalse(string.startsWith('Abcdef', 'ghi'))
end

function suite.startsWith_isFalse_onLongerNeedle()
	test.isFalse(string.startsWith('Abc', 'Abcdef'))
end

function suite.startsWith_isFalse_onEmptyHaystack()
	test.isFalse(string.startsWith('', 'Abc'))
end

function suite.startsWith_isTrue_onEmptyNeedle()
	test.isTrue(string.startsWith('Abcdef', ''))
end
