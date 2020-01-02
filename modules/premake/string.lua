---
-- Overrides and extensions to Lua's `string` library.
---

function string.findLast(self, pattern, plain)
	local i = 0

	repeat
		local next = string.find(self, pattern, i + 1, plain)
		if next then
			i = next
		end
	until (not next)

	if i > 0 then
		return i
	end
end


function string.split(self, pattern, plain, limit)
	local result = {}

	local pos = 0
	local count = 0

	local iter = function()
		return string.find(self, pattern, pos, plain)
	end

	for start, stop in iter do
		table.insert(result, string.sub(self, pos, start - 1))
		pos = stop + 1
		count = count + 1
		if limit ~= nil and count == limit then
			break
		end
	end

	table.insert(result, string.sub(self, pos))
	return result
end
