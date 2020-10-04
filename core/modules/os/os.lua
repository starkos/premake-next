---
-- Overrides and extensions to Lua's `os` library.
---

local path = require('path')


function os.matchDirs(mask)
	local result = {}
	os._match(result, mask, 'dir')
	return result
end


function os.matchFiles(mask)
	local result = {}
	os._match(result, mask, 'file')
	return result
end


function os._match(results, mask, type)
	mask = path.normalize(mask)

	-- split the mask at the first path segment that contains a wildcard
	local remainder

	local wildcardPos = mask:find('*', 1, true)
	if wildcardPos then
		local slashAfterWildcardPos = mask:find('/', wildcardPos, true)
		if slashAfterWildcardPos then
			remainder = mask:sub(slashAfterWildcardPos + 1)
			mask = mask:sub(1, slashAfterWildcardPos - 1)
		end
	end

	local directory = path.getDirectory(mask)
	local pattern = path.getName(mask)

	-- define an iterator to walk over matches
	function matches(directory, pattern)
		local matcher = os.matchStart(directory, pattern)
		return function()
			local next = os.matchNext(matcher)
			if next then
				local matched = path.join(directory, os.matchName(matcher))
				if os.isFile(matched) then
					return matched, 'file'
				else
					return matched, 'dir'
				end
			end
			os.matchDone(matcher)
		end
	end

	-- check the current dir for matches to the rest of the mask
	if remainder and pattern == '**' then
		os._match(results, path.join(directory, remainder), type)
	end

	for matched, matchType in matches(directory, pattern) do
		-- if `pattern` occurs at the end of the mask, add matches to the results
		if not remainder and matchType == type then
			table.insert(results, matched)
		end

		-- recurse into subdirs, looking for the rest of the mask
		if matchType == 'dir' then
			if pattern == '**' then
				-- recurse into subdirs, looking for the rest of the mask
				os._match(results, path.join(matched, '**', remainder), type)
			elseif remainder then
				os._match(results, path.join(matched, remainder), type)
			end
		end
	end
end


return os
