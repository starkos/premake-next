---
-- Overrides and extensions to Lua's `table` library.
---

function table.contains(self, value)
	for _, v in pairs(self) do
		if v == value then
			return true
		end
	end
	return false
end
