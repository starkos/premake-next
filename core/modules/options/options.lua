---
-- Command line option handling.
---

local p = require('premake')

local m = {}

m._definitions = {}
m._values = nil


function commandLineOption(definition)
	local ok, err = m.register(definition)
	if not ok then
		error(err, 2)
	end
end


function m.register(definition)
	local ok, err = p.checkRequired(definition, 'trigger', 'description')
	if not ok then
		return false, err
	end

	-- store it
	m._definitions[definition.trigger] = definition

	-- new definition requires option values to be parsed again
	m._values = nil

	return true
end


function m.all()
	local i = 0

	return function()
		while i < #_ARGS do
			i = i + 1
			local arg = _ARGS[i]

			local trigger, value = m._splitTriggerFromValueIfPresent(arg)

			if not value then
				local def = m.definitionOf(trigger)
				if def and def.value then
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


function m.definitionOf(trigger)
	return m._definitions[trigger]
end


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


function m.execute(trigger, value)
	local def = m.definitionOf(trigger)
	if def and def.execute then
		def.execute(value)
	end
end


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


function m.getKind(trigger)
	if string.startsWith(trigger, '-') then
		return 'option'
	else
		return 'action'
	end
end


function m.isSet(trigger)
	return (m.valueOf(trigger) ~= nil)
end


function m.validate()
	for trigger, _ in m.all() do
		local def = m.definitionOf(trigger)
		if not def then
			return false, string.format('invalid option "%s"', trigger)
		end
	end
	return true
end


function m.valueOf(trigger)
	if not m._values then
		m._values = m._parseArgs()
	end

	local def = m.definitionOf(trigger)
	if def then
		return m._values[def.trigger] or def.default
	end
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
