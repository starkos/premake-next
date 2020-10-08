---
-- The main program logic flow.
--
-- Bootstraps the core APIs used by the rest of the application, and implements
-- the program entry point and overall execution flow.
---

local options = require('options')
local p = require('premake')
local path = require('path')

local m = {}

m.PROJECT_SCRIPT_NAME = 'premake6.lua'
m.SYSTEM_SCRIPT_NAME = 'premake6-system.lua'

doFile('./core-fields.lua')
doFile('./core-options.lua', m)
doFile('./core-modules.lua')

-- Bootstrapping functions, in execution order

function m.runSystemScript()
	local name = options.valueOf('--systemscript')

	if name ~= m.SYSTEM_SCRIPT_NAME and not os.isFile(name) then
		error(string.format('no such file `%s`', name), 0)
	end

	doFileOpt(name)
end


function m.locateProjectScript()
	local name = options.valueOf('--file')

	if name ~= m.PROJECT_SCRIPT_NAME and not os.isFile(name) then
		error(string.format('no such file `%s`', name), 0)
	end

	local location = p.locateScript(name) or name
	_PREMAKE.MAIN_SCRIPT = location
	_PREMAKE.MAIN_SCRIPT_DIR = path.getDirectory(location)
end


function m.runProjectScript()
	doFileOpt(_PREMAKE.MAIN_SCRIPT)
end


function m.validateCommandLineOptions()
	local ok, err = options.validate()
	if not ok then
		error(err, 0)
	end
end


function m.executeCommandLineOptions()
	if #_ARGS > 0 then
		for trigger, value in options.each() do
			_G._ACTION = trigger
			options.execute(trigger, value)
		end
	else
		printf('Type `%s --help` for help', path.getName(_ARGS[0]))
	end
end


---
-- Main program entry point
---

m.steps = {
	m.runSystemScript,
	m.locateProjectScript,
	m.runProjectScript,
	m.validateCommandLineOptions,
	m.executeCommandLineOptions
}

function m.run()
	p.callArray(m.steps)
end


return m
