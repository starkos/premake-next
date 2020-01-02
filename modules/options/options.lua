---
-- Premake command line option handling.
---

local m = {}

m._definitions = {}
m._values = nil


function commandLineOption(definition)
	local ok, err = m.register(definition)
	if not ok then
		error(err, 2)
	end
end


---
-- Register a new command line option.
--
-- @returns
--    If successful, returns `true`. Otherwise returns `false` and an error message.
---
function m.register(definition)
	-- validate the new option just a bit
	local required = { 'trigger', 'description' }
	for i = 1, #required do
		local field = required[i]
		if not definition[field] then
			return false, string.format('missing required value "%s"', field)
		end
	end

	-- store it
	m._definitions[definition.trigger] = definition

	-- new definition requires option values to be parsed again
	m._values = nil

	return true
end


---
-- Iterate over all command line arguments, including those that do not match
-- any registered option definition. Will use best guess as to the value of
-- any unregistered options.
--
-- @returns
--    Each call return the next trigger-value pair, until `nil`.
---
function m.all()
	local i = 0

	return function()
		while i < #_ARGS do
			i = i + 1
			local arg = _ARGS[i]

			local trigger, value = m._splitTriggerFromValueIfPresent(arg)

			if not value then
				local def = m.definitionOf(trigger)
				if def then
					i = i + 1
					value = _ARGS[i]
				else
					value = _ARGS[i + 1]
				end
			end

			return trigger, value or ""
		end
	end
end


---
-- Return the definition associated with specific trigger, as provided to `register()`.
---
function m.definitionOf(trigger)
	return m._definitions[trigger]
end



---
-- Iterate each of the valid options present in the current command line arguments.
-- Skips over any args which do not match a registered option.
--
-- @returns
--    Each call return the next trigger-value pair, until `nil`.
---
function m.each()
	local it = m.all()

	return function()
		local trigger, value = it()
		while trigger do
			local def = m.definitionOf(trigger)
			if def then
				return trigger, value
			end
			trigger, value = it()
		end
	end
end


---
-- Calls the function associated with the specified option, if one exists,
-- passing in the provided value.
---
function m.execute(trigger, value)
	local def = m.definitionOf(trigger)
	if def and def.execute then
		def.execute(value)
	end
end



---
-- Return an array of registered option definitions, sorted by trigger.
---
function m.getDefinitions()
	local result = {}

	for _, def in pairs(m._definitions) do
		table.insert(result, def)
	end

	table.sort(result, function(a, b)
		return a.trigger < b.trigger
	end)

	return result
end


---
-- Returns true if the trigger represents an action, as opposed to an option.
-- Options start with leading dashes.
---
function m.getKind(trigger)
	if string.startsWith(trigger, '-') then
		return 'option'
	else
		return 'action'
	end
end


---
-- Validate the current command line arguments against the collection of
-- registered option definitions.
--
-- @returns
--    True if successful, else false and an error message.
---
function m.validate()
	for trigger, _ in m.all() do
		local def = m.definitionOf(trigger)
		if not def then
			return false, string.format('invalid option "%s"', trigger)
		end
	end
	return true
end


---
-- Return the command line value associated with a specific trigger, if any.
---
function m.valueOf(trigger)
	if not m._values then
		m._values = m._parseArgs()
	end

	local def = m.definitionOf(trigger)
	return m._values[def.trigger] or def.default
end


---
-- Iterate over the command line arguments and return a table of trigger-value
-- pairs for any registered options found.
---
function m._parseArgs()
	local values = {}

	for trigger, value in m.each() do
		values[trigger] = value
	end

	return values
end


---
-- If the arg is of the form "trigger=value", split on the "=" and return
-- the split trigger-value pair.
---
function m._splitTriggerFromValueIfPresent(arg)
	local splitAt = string.find(arg, '=', 1, true)
	if splitAt then
		return string.sub(arg, 1, splitAt - 1), string.sub(arg, splitAt + 1)
	else
		return arg, nil
	end
end


return m
