---
-- Extensions to Lua's global functions.
---

---
-- Extend Lua's `dofile()` function to accept a variable list of arguments
-- to be passed into the called script.
--
-- To access an argument from the within the called script, use `select`:
--
-- ```
--  local arg1 = select(1, ...)
--  local arg2 = select(2, ...)
-- ```
--
-- @param filename
--    The name of the script to be run.
-- @param ...
--    A variable list of arguments to be passed to the script.
---
function doFile(filename, ...)
	local chunk, err = loadFile(filename)
	if err then
		error(err, 2)
	end
	return (chunk(...))
end


---
-- Like `doFile()`, but returns without error if the specified file does not exist.
-- it does not.
--
-- @param filename
--    The name of the file to load.
-- @param ...
--    A variable list of arguments to be passed to the script.
---
function doFileOpt(filename, ...)
	local chunk, err = loadFileOpt(filename);
	if err then
		error(err, 2)
	end
	if chunk then
		return (chunk(...))
	end
end
