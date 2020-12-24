local Dom = require('dom')
local premake = require('premake')
local path = require('path')

local vstudio = select(1, ...)

local workspace = {}


function workspace.extract(state, name)
	local wks = Dom.Workspace.new(state:select({ workspaces = name }))
	wks.global = state
	wks.exportPath = vstudio.sln.filename(wks)

	local projects = {}

	local names = wks.projects
	for i = 1, #names do
		projects[i] = vstudio.project.extract(wks, names[i])
	end

	wks.projects = projects
	return wks
end


function workspace.export(wks)
	premake.export(wks, wks.exportPath, vstudio.sln.export)
end


return workspace
