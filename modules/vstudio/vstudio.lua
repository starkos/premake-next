local path = require('path')
local premake = require('premake')
local State = require('state')
local Dom = require('dom')

local vstudio = {}

vstudio.project = doFile('./src/project.lua', vstudio)
vstudio.workspace = doFile('./src/workspace.lua', vstudio)


function vstudio.export(version)
	local workspaces = vstudio.extractWorkspaces(version)

	for wi = 1, #workspaces do
		local wks = workspaces[wi]
		printf('Exporting workspace "%s"...', wks.name)
		premake.export(wks, wks.exportPath, vstudio.workspace.export)

		for pi = 1, #wks.projects do
			local prj = wks.projects[pi]
			printf('Exporting project "%s"...', prj.name)
			premake.export(prj, prj.exportPath, vstudio.project.export)
		end
	end
end


function vstudio.extractWorkspaces(version)
	local state = State.new(premake.store(), {
		action = 'vstudio',
		version = version
	})

	local workspaces = Dom.Workspace.extractAll(state, State.INHERIT)
	for wi = 1, #workspaces do
		local wks = workspaces[wi]
		vstudio.prepareWorkspace(wks)

		local projects = Dom.Project.extractAll(wks, State.INHERIT)
		for pi = 1, #projects do
			vstudio.prepareProject(projects[pi])
		end

		wks.projects = projects
	end

	return workspaces
end


function vstudio.prepareWorkspace(wks)
	printf('Configuring workspace "%s"...', wks.name)
	wks.exportPath = path.join(wks.location, wks.filename) .. '.sln'
end


function vstudio.prepareProject(prj)
	printf('Configuring project "%s"...', prj.name)
	prj.exportPath = path.join(prj.location, prj.filename) .. '.vcxproj'
end


return vstudio
