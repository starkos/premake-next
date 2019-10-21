---
-- Overrides and extensions to Lua's `string` library.
---

---
-- Split a string on boundaries formed by `pattern`.
--
-- @param pattern
--    The pattern on which to split the string.
-- @param plain
--    If true, `pattern` is treated as a plain string to match, rather
--    than a Lua pattern.
-- @param limit
--    An upper limit on the number splits to make.
-- @return
--    An array of strings.
---
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
