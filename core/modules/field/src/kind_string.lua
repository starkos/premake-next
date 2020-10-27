local Field = select(1, ...)

Field.registerKind('string', {
	default = function()
		return nil
	end,


	merge = function(field, currentValue, newValue)
		if type(newValue) == 'table' then
			error('expected string; got table')
		end
		return newValue
	end,


	remove = function(field, currentValue, valuesToRemov)
		return nil
	end,


	match = function(field, value, pattern, innerMatch, plain)
		if value ~= nil then
			local startAt, endAt = string.find(value, pattern, 1, plain)
			return (startAt == 1 and endAt == #value)
		end
	end
})
