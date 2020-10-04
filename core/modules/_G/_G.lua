---
-- Extensions to Lua's global functions.
---

local path = _PREMAKE.path
local premake = _PREMAKE.premake

local Callback = require('callback')

package.registered = {}

local _onRequireCallbacks = {}

local EMPTY = {}


local function _typeIndexer(self, key)
	return self[key]
end


---
-- Declare a new "type", which is basically a namespace with support for ":" calling,
-- like Lua's built-in string library.
---

function declareType(typeName, extends)
	local newType = table.mergeKeys(extends or EMPTY, {
		__typeName = typeName,
		__extends = extends
	})

	if extends ~= nil then
		newType.__index = function(self, key)
			return newType[key] or extends.__index(self, key)
		end
	else
		newType.__index = function(self, key)
			return newType[key]
		end
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
	return setmetatable(initialValues or {}, type)
end


function onRequire(moduleName, fn)
	local callbacks = _onRequireCallbacks[moduleName] or {}
	table.insert(callbacks, Callback.new(fn))
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

	local callbacks = _onRequireCallbacks[moduleName] or EMPTY
	for i = 1, #callbacks do
		Callback.call(callbacks[i], module)
	end

	return module
end


function tryRegister(module)
	if package.registered[module] then
		return true
	end

	local location = premake.locateModule(module)
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
