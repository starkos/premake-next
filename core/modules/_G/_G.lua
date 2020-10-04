---
-- Extensions to Lua's global functions.
---

local p = _PREMAKE.premake
local path = _PREMAKE.path

package.registered = {}

local _onRequireCallbacks = {}


local function _typeIndexer(self, key)
	return self[key]
end


---
-- Declare a new "type", which is basically a namespace with support for ":" calling,
-- like Lua's built-in string library.
---

function declareType(typeName)
	local newType = {
		__typeName = typeName
	}

	newType.__index = function(self, key)
		return newType[key]
	end

	return newType
end


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


---
-- Instantiate a new instance of a "type", which may call into the type's methods using
-- Lua's ":" syntax, e.g. `newType:myMethod()`.
---

function instantiateType(type, initialValues)
	return setmetatable(initialValues, type)
end


function onRequire(moduleName, fn)
	local callbacks =_onRequireCallbacks[moduleName] or {}

	table.insert(callbacks, {
		fn = fn,
		_SCRIPT_DIR = _SCRIPT_DIR
	})

	_onRequireCallbacks[moduleName] = callbacks
end


function printf(msg, ...)
	print(string.format(msg or '', ...))
end


function register(module)
	local ok, err = tryRegister(module)
	if not ok then
		error(err, 2)
	end
end


local _builtInRequire = require

function require(moduleName)
	local module = _builtInRequire(moduleName)

	local callbacks = _onRequireCallbacks[moduleName] or {}
	for i = 1, #callbacks do
		local callback = callbacks[i]
		callback.fn(module)
	end

	return module
end


function tryRegister(module)
	if package.registered[module] then
		return true
	end

	local location = p.locateModule(module)
	if not location then
		return false, string.format('Module `%s` not found', module)
	end

	local scriptPath = path.join(path.getDirectory(location), '_register.lua')
	doFileOpt(scriptPath)

	package.registered[module] = scriptPath;
	return true
end


function typeOf(instance)
	local ret

	local metatable = getmetatable(instance)
	if metatable ~= nil then
		ret = metatable.__typeName
	end

	return ret or type(instance)
end


return _G
