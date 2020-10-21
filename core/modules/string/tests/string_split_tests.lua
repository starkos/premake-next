local StringSplitTests = test.declare('StringSplitTests', 'string')


function StringSplitTests.split_returnsUnchanged_onNoMatch()
	test.isEqual({ 'aaa' }, string.split('aaa', '/', true))
end

function StringSplitTests.split_splitsCorrectly_onPlainText()
	test.isEqual({ 'aaa', 'bbb', 'ccc' }, string.split('aaa/bbb/ccc', '/', true))
end
