local path = require('path')

local Field = select(1, ...)

Field.registerKind('path', {
	default = function()
		return nil
	end,

	merge = function(field, currentValue, newValue)
		return path.getAbsolute(path.join(_SCRIPT_DIR, newValue))
	end,

	remove = function(field, currentValue, valuesToRemov)
		return currentValue
	end,

	match = function(field, value, pattern, innerMatch, plain)
		if value ~= nil then
			local startAt, endAt = string.find(value, pattern, 1, plain)
			return (startAt == 1 and endAt == #value)
		end
	end
})
