local premake = require('premake')
local State = require('state')

local vstudio = {}


-- load in this module's components
local _MODULES = {  'Config', 'Project', 'Workspace', 'sln', 'vcxproj' }
for _, module in pairs(_MODULES) do
	vstudio[module] = doFile('./src/' .. module:lower() .. '.lua', vstudio)
end


local _VERSION_INFO = {
	['2010'] = {
		solutionFileFormatVersion = '11',
		toolsVersion = "4.0",
		visualStudioVersion = '2010',
	},
	['2012'] = {
		solutionFileFormatVersion = '12',
		toolsVersion = "4.0",
		visualStudioVersion = '2012'
	},
	['2015'] = {
		solutionFileFormatVersion = '12',
		toolsVersion = "14.0",
		visualStudioVersion = '14'
	},
	['2017'] = {
		solutionFileFormatVersion = '12',
		toolsVersion = "15.0",
		visualStudioVersion = '15'
	},
	['2019'] = {
		solutionFileFormatVersion = '12',
		visualStudioVersion = 'Version 16',
	}
}


---
-- Visual Studio exporter entry point.
---

function vstudio.export(version)
	vstudio.setTargetVersion(version)

	local state = premake.newState({
		action = 'vstudio',
		version = version
	})

	printf('Configuring...')
	local workspaces = vstudio.Workspace.extractAll(state)

	for i = 1, #workspaces do
		local wks = workspaces[i]
		printf('Exporting %s...', wks.name)
		wks:export()
	end

	print('Done.')
end


---
-- Specifies which version of Visual Studio is being targeted. Causes
-- `vstudio.currentVersion` to be set to a table of version-specific
-- properties for use by the exporter logic.
--
-- @param version
--    The target version, i.e. '2015' or '2019'.
---

function vstudio.setTargetVersion(version)
	local versionInfo = _VERSION_INFO[tostring(version)]

	if versionInfo == nil then
		error(string.format('Unsupported Visual Studio version "%s"', version))
	end

	vstudio.currentVersion = versionInfo
end


return vstudio
