local premake = require('premake')
local State = require('state')

local vstudio = {}

-- load in this module's components
local _MODULES = {  'project', 'workspace', 'sln', 'vcxproj' }
for _, module in pairs(_MODULES) do
	vstudio[module] = doFile('./src/' .. module .. '.lua', vstudio)
end

local _VERSION_INFO = {
	['2010'] = {
		solutionFileFormatVersion = '11',
		toolsVersion = "4.0",
		visualStudioVersion = '2010'
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

	printf('Configuring...')
	local workspaces = vstudio.extractWorkspaces()

	for i = 1, #workspaces do
		printf('Exporting %s...', workspaces[i].name)
		vstudio.exportWorkspace(workspaces[i])
	end

	print('Done.')
end


---
-- Extracts all workspaces and their contained projects, etc. from the current
-- global store and prepares them for use by the Visual Studio exporters.
---

function vstudio.extractWorkspaces()
	local state = premake.newState({
		action = 'vstudio',
		version = version
	})

	local workspaces = {}
	local names = state.workspaces
	for i = 1, #names do
		workspaces[i] = vstudio.workspace.extract(state, names[i])
	end

	return workspaces
end


---
-- Export a workspace and its contained projects, etc.
---

function vstudio.exportWorkspace(wks)
	vstudio.workspace.export(wks)
	local projects = wks.projects
	for i = 1, #projects do
		vstudio.project.export(projects[i])
	end
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
