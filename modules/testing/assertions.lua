---
-- Unit testing framework assertion library
---

local m = select(1, ...)


function m.fail(format, ...)
	local args = { ... }
	local depth = 3

	-- if format is a number then it is the stack depth
	if type(format) == 'number' then
		depth = depth + format
		format = table.remove(args, 1)
	end

	for i = 1, #args do
		local arg = args[i]
		if arg == nil then
			arg = '(nil)'
		elseif type(arg) == 'table' then
			arg[i] = string.format('{%s}', table.concat(arg[i], ', '))
		end
	end

	local msg = string.format(format, table.unpack(args))
	error(debug.traceback(msg, depth), depth)
end


function m.isEqual(expected, actual, depth)
	local function test(expected, actual, depth)
		if type(expected) == 'table' then
			if expected and not actual then
				m.fail(depth, 'expected table, got nil')
			end

			if #expected < #actual then
				m.fail(depth, 'expected %d items, got %d', #expected, #actual)
			end

			for k, v in pairs(expected) do
				test(expected[k], actual[k], depth + 1)
			end
		else
			if expected ~= actual then
				m.fail(depth, 'expected `%s` but was `%s`', expected, actual or 'nil')
			end
		end
	end

	test(expected, actual, 1)
	return true
end


function m.isFalse(actual)
	if actual then
		m.fail('expected false but was true')
	end
end


function m.isNil(actual)
	if actual ~= nil then
		m.fail('expected nil but was `%s`', tostring(actual))
	end
end


function m.isNotNil(actual)
	if actual == nil then
		m.fail('expected non-nil but was `%s`', tostring(actual))
	end
end


function m.isTrue(actual)
	if not actual then
		m.fail('expected true but was false')
	end
end
