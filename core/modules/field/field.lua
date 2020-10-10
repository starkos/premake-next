---
-- Fields represent a configurable value which can be specified via user
-- script and retrieved via queries. A field has a "kind", such as `string`
-- for a simple string value, or `list:string` for a list of strings.
---

local Callback = require('callback')

local Field = declareType('Field')

local _registeredFields = {}
local _onFieldAddedCallbacks = {}
local _onFieldRemovedCallbacks = {}


---
-- Create and register a new field.
--
-- @param definition
--    A table describing the new field, with these keys:
--
--    - name     A unique string name for the field, to be used to identify
--               the field in future operations.
--    - kind     The kind of values that can be stored into this field. Kinds
--               can be chained together to create more complex types, such as
--               "list:string".
--
-- @return
--    A populated field object. Or nil and an error message if the field could
--    not be registered.
---

function Field.new(definition)
	local field = instantiateType(Field, {
		name = definition.name,
		kind = definition.kind,
		allowed = definition.allowed
	})

	_registeredFields[field.name] = field

	for i = 1, #_onFieldAddedCallbacks do
		Callback.call(_onFieldAddedCallbacks[i], field)
	end

	return field
end


---
-- Tests a pattern against field value(s); returns true if the pattern can be matched.
---

function Field.contains(self, value, pattern, plain)
	-- just to get things going
	if type(value) == 'table' then
		for i = 1, #value do
			local value = value[i]
			local startAt, endAt = string.find(value, pattern, 1, plain)
			if (startAt == 1 and endAt == #value) then
				return true
			end
		end
		return false
	else
		local startAt, endAt = string.find(value, pattern, 1, plain)
		return (startAt == 1 and endAt == #value)
	end
end


---
-- Return the default (empty) value for the field.
--
-- @returns
--    For strings and other simple object types, returns `nil`. For lists and
--    other collection types, returns an empty collection.
---

function Field.defaultValue(self)
	-- just to get things doing
	if self.kind == 'list:string' then
		return {}
	else
		return nil
	end
end


---
-- Remove a field previously registered with `new()`.
---

function Field.delete(self)
	if _registeredFields[self.name] ~= nil then
		for i = 1, #_onFieldRemovedCallbacks do
			Callback.call(_onFieldRemovedCallbacks[i], self)
		end
		_registeredFields[self.name] = nil
	end
end


---
-- Enumerate all available fields.
---

function Field.each()
	local iterator = pairs(_registeredFields)
	local name, field
	return function()
		name, field = iterator(_registeredFields, name)
		return field
	end
end


---
-- Return true if a field with the given name has been registered.
---

function Field.exists(fieldName)
	return (_registeredFields[fieldName] ~= nil)
end


---
-- Fetch a field by name.
---

function Field.get(fieldName)
	local fld = _registeredFields[fieldName]
	if not fld then
		error(string.format('No such field `%s`', fieldName), 2)
	end
	return fld
end


---
-- Merge value(s) to a field.
--
-- For simple values, the new value will replace the old one. For collections,
-- the new values will be appeneded.
---

function Field.mergeValues(self, currentValue, newValue)
	-- just to get things going
	if self.kind == 'list:string' then
		return table.joinArrays(currentValue or Field.defaultValue(self), newValue)
	else
		return newValue
	end
end


function Field.onFieldAdded(fn)
	table.insert(_onFieldAddedCallbacks, Callback.new(fn))
end


function Field.onFieldRemoved(fn)
	table.insert(_onFieldRemovedCallbacks, Callback.new(fn))
end


---
-- Remove value(s) from a field.
---

function Field.removeValues(self, currentValue, patternsToRemove)
	-- just to get things going
	if self.kind == 'list:string' then
		local result = {}
		local removed = {}

		table.forEach(currentValue or Field.defaultValue(self), function(value)
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
	else
		-- not a collection type
		return currentValue
	end
end


return Field
