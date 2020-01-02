---
-- The main Premake module.
--
-- Bootstraps the core APIs used by the rest of the application, and implements
-- the program entry point and overall execution flow.
---

local m = _PREMAKE.premake

_PREMAKE.VERSION = '6.0.0-next'
_PREMAKE.COPYRIGHT = 'Copyright (C) 2002-2020 Jason Perkins and the Premake Project'
_PREMAKE.WEBSITE = 'https://github.com/starkos/premake-next'

m.PROJECT_SCRIPT_NAME = 'premake6.lua'
m.SYSTEM_SCRIPT_NAME = 'premake6-system.lua'


-- load extensions to Lua
doFile('libraries/_G.lua')
doFile('libraries/string.lua')

-- pull in supporting parts of this module
doFile('libraries/premake.lua', m)

local options = require('options')
local path = require('path')


-- Register the core command line options

commandLineOption {
	trigger = '--file',
	description = string.format('Read FILE as a Premake script; default is "%s"', m.PROJECT_SCRIPT_NAME),
	value = 'FILE',
	default = m.PROJECT_SCRIPT_NAME
}

-- TODO: Move to help module once I've implemented `register()`
commandLineOption {
	trigger = '--help',
	description = 'Display this information',
	execute = function()
		local help = require('help')
		help.printHelp()
	end
}

commandLineOption {
	trigger = '--scripts',
	description = "Search for additional scripts on the given path",
	value = 'PATH'
}

commandLineOption {
	trigger = '--systemscript',
	description = string.format('Override default system script (%s)', m.SYSTEM_SCRIPT_NAME),
	value = 'FILE',
	default = m.SYSTEM_SCRIPT_NAME
	-- handled in premake.c
}

commandLineOption {
	trigger = '--version',
	description = 'Display version information',
	execute = function()
		print(string.format('Premake Build Script Generator version %s', _PREMAKE.VERSION))
	end
}


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

	local location = m.locateScript(name) or name
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

function m.main()
	m.callArray(m.steps)
end


return m
