local TableCollectUniqueTests = test.declare('TableCollectUniqueTests', 'table')


function TableCollectUniqueTests.collectsAll_onAllUnique()
	local data = {
		{ value = 'a' },
		{ value = 'b' },
		{ value = 'c' }
	}
	local result = table.collectUnique(data, function (item) return item.value end)
	test.isEqual({ 'a', 'b', 'c'}, result)
end


function TableCollectUniqueTests.skipsDuplicates()
	local data = {
		{ value = 'a' },
		{ value = 'b' },
		{ value = 'a' },
		{ value = 'c' },
	}
	local result = table.collectUnique(data, function (item) return item.value end)
	test.isEqual({ 'a', 'b', 'c'}, result)
end


function TableCollectUniqueTests.skipsNils()
	local data = {
		{ value = 'a' },
		{ value = 'b' },
		{ value = nil },
		{ value = 'c' },
	}
	local result = table.collectUnique(data, function (item) return item.value end)
	test.isEqual({ 'a', 'b', 'c'}, result)
end
