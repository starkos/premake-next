---
-- Premake helper APIs.
---

local State = require('state')
local Store = require('store')

local premake = _PREMAKE.premake

_PREMAKE.VERSION = '6.0.0-next'
_PREMAKE.COPYRIGHT = 'Copyright (C) 2002-2020 Jason Perkins and the Premake Project'
_PREMAKE.WEBSITE = 'https://github.com/starkos/premake-next'

local _env = {}
local _store = Store.new()
local _testStateSnapshot


onRequire('testing', function (testing)
	local snapshot

	testing.onBeforeTest(function ()
		snapshot = Store.snapshot(_store)
		Store.rollback(_store, _testStateSnapshot)
	end)

	testing.onAfterTest(function ()
		Store.rollback(_store, snapshot)
	end)
end)


function premake.callArray(funcs, ...)
	if type(funcs) == 'function' then
		funcs = funcs(...)
	end
	if funcs then
		for i = 1, #funcs do
			funcs[i](...)
		end
	end
end


function premake.checkRequired(obj, ...)
	local n = select('#', ...)
	for i = 1, n do
		local field = select(i, ...)
		if not obj[field] then
			return false, string.format('missing required value `%s`', field)
		end
	end
	return true
end


function premake.env()
	return _env
end


local _eol

function premake.eol(newValue)
	_eol = newValue or _eol
	return _eol
end


function premake.export(obj, exportPath, exporter)
	local contents = io.capture(function ()
		exporter(obj)
	end)

	if not io.compareFile(exportPath, contents) then
		io.writeFile(exportPath, contents)
	end
end


function premake.select(env)
	return State.new(_store, table.mergeKeys(_env, env))
end


---
-- Creates a snapshot of the current store state, before the user's project script
-- has run, to enable automated testing without picking up user project artifacts.
---

function premake.snapshotStateForTesting()
	_testStateSnapshot = Store.snapshot(_store)
end


function premake.store()
	return _store
end


return premake
