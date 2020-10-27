local Field = select(1, ...)

Field.registerKind('list', {
	default = function()
		return _EMPTY
	end,


	merge = function(field, currentValues, newValues)
		return table.joinArrays(currentValues or _EMPTY, newValues)
	end,


	remove = function(field, currentValues, patternsToRemove)
		local result = {}
		local removed = {}

		table.forEach(currentValues or _EMPTY, function(value)
			for i = 1, #patternsToRemove do
				if string.match(value, patternsToRemove[i]) then
					table.insert(removed, value)
					return -- value is removed; skip to next value
				end
			end
			-- was not removed; add to new results
			table.insert(result, value)
		end)

		return result, removed
	end,


	match = function(field, values, pattern, innerMatch, plain)
		for i = 1, #values do
			if innerMatch(field, values[i], pattern, plain) then
				return true
			end
		end
	end
})
