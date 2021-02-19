local premake = require('premake')
local State = require('state')

local vstudio = {}

vstudio.Config = doFile('./src/config.lua', vstudio)
vstudio.Project = doFile('./src/project.lua', vstudio)
vstudio.Workspace = doFile('./src/workspace.lua', vstudio)

vstudio.sln = doFile('./src/sln.lua', vstudio)
vstudio.vcxproj = doFile('./src/vcxproj.lua', vstudio)
vstudio.vcxproj.filters = doFile('./src/vcxproj.filters.lua', vstudio)
vstudio.vcxproj.utils =  doFile('./src/vcxproj.utils.lua', vstudio)


local _VERSION_INFO = {
	['2010'] = {
		filterToolsVersion = '4.0',
		solutionFileFormatVersion = '11',
		toolsVersion = '4.0',
		visualStudioVersion = '2010',
	},
	['2012'] = {
		filterToolsVersion = '4.0',
		solutionFileFormatVersion = '12',
		toolsVersion = '4.0',
		visualStudioVersion = '2012'
	},
	['2013'] = {
		filterToolsVersion = '4.0',
		solutionFileFormatVersion = '12',
		toolsVersion = '12.0'
	},
	['2015'] = {
		filterToolsVersion = '4.0',
		solutionFileFormatVersion = '12',
		toolsVersion = '14.0',
		visualStudioVersion = '14'
	},
	['2017'] = {
		filterToolsVersion = '4.0',
		solutionFileFormatVersion = '12',
		toolsVersion = '15.0',
		visualStudioVersion = '15'
	},
	['2019'] = {
		filterToolsVersion = '4.0',
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
-- Specifies which version of Visual Studio is being targeted. Causes `vstudio.targetVersion` to
-- be set to a table of version-specific properties for use by the exporter logic.
--
-- @param version
--    The target version, i.e. '2015' or '2019'.
---

function vstudio.setTargetVersion(version)
	local versionInfo = _VERSION_INFO[tostring(version)]

	if versionInfo == nil then
		error(string.format('Unsupported Visual Studio version "%s"', version))
	end

	vstudio.targetVersion = versionInfo
end


return vstudio
