---
-- The main Premake module.
--
-- Bootstraps the core APIs used by the rest of the application, and implements
-- the program entry point and overall execution flow.
---

local m = _PREMAKE.premake

m.PROJECT_SCRIPT_NAME = 'premake6.lua'
m.SYSTEM_SCRIPT_NAME = 'premake6-system.lua'


-- load extensions to Lua
doFile('libraries/_G.lua')
doFile('libraries/string.lua')

-- pull in supporting parts of this module
doFile('libraries/premake.lua', m)

local args = require('premake-args')
local path = require('path')


function m.runSystemScript()
	local name = _OPTIONS['systemscript'] or m.SYSTEM_SCRIPT_NAME
	doFileOpt(name)
end


function m.locateProjectScript()
	local name = _OPTIONS['file'] or m.PROJECT_SCRIPT_NAME
	local location = m.locateScript(name) or name
	_PREMAKE.MAIN_SCRIPT = location
	_PREMAKE.MAIN_SCRIPT_DIR = path.getDirectory(location)
end


function m.runProjectScript()
	doFileOpt(_PREMAKE.MAIN_SCRIPT)
end


---
-- Main program entry point
---

m.steps = {
	m.runSystemScript,
	m.locateProjectScript,
	m.runProjectScript
}

function m.main()
	m.callArray(m.steps)
end


return (m)
