---
-- Extensions to Lua's global functions.
---

function doFile(filename, ...)
	local chunk, err = loadFile(filename)
	if err then
		error(err, 2)
	end
	return (chunk(...))
end


function doFileOpt(filename, ...)
	local chunk, err = loadFileOpt(filename);
	if err then
		error(err, 2)
	end
	if chunk then
		return (chunk(...))
	end
end


function printf(msg, ...)
	print(string.format(msg or '', ...))
end
