local Dom = require('dom')
local premake = require('premake')
local State = require('state')

local vstudio = {}

local _MODULES = {  'project', 'workspace', 'sln', 'vcxproj' }
for _, module in pairs(_MODULES) do
	vstudio[module] = doFile('./src/' .. module .. '.lua', vstudio)
end


function vstudio.export(version)
	vstudio.setTargetVersion(version)

	local state = premake.select({
		action = 'vstudio',
		version = version
	})

	local workspaces = vstudio.extractWorkspaces(state)
	vstudio.exportWorkspaces(workspaces)
end


function vstudio.extractWorkspaces(state)
	print('Configuring...')

	local workspaces = Dom.Workspace.extractAll(state, State.INHERIT)

	for wi = 1, #workspaces do
		local wks = workspaces[wi]
		printf('  %s', wks.name)
		vstudio.workspace.prepare(wks)

		local projects = Dom.Project.extractAll(wks, State.INHERIT)

		for pi = 1, #projects do
			local prj = projects[pi]
			printf('  %s', prj.name)
			vstudio.project.prepare(prj)
		end

		wks.projects = projects
	end

	return workspaces
end


function vstudio.exportWorkspaces(workspaces)
	print('Exporting...')

	for wi = 1, #workspaces do
		local wks = workspaces[wi]
		printf('  %s', wks.name)
		vstudio.workspace.export(wks)

		for pi = 1, #wks.projects do
			local prj = wks.projects[pi]
			printf('  %s', prj.name)
			vstudio.project.export(prj)
		end
	end
end


function vstudio.setTargetVersion(version)
	vstudio._VERSION = version
end


return vstudio
