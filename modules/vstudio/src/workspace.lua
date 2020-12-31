---
-- Visual Studio helper methods for workspaces.
---

local dom = require('dom')
local premake = require('premake')

local vstudio = select(1, ...)

local Workspace = declareType('Workspace', dom.Workspace)


---
-- Extract and return a list of all workspaces in a state.
--
-- @param rootState
--    The root state instance.
-- @returns
--    A list of workspaces found in the state.
---

function Workspace.extractAll(rootState)
	local workspaces = {}

	local names = rootState.workspaces
	for i = 1, #names do
		workspaces[i] = Workspace.extract(rootState, names[i])
	end

	return workspaces
end


---
-- Extra a workspace state instance from the root state.
--
-- @param rootState
--    The root state instance.
-- @param name
--    The name of the workspace to extract.
-- @returns
--    The corresponding workspace object.
---

function Workspace.extract(rootState, name)
	local wks = instantiateType(Workspace, dom.Workspace.new(rootState
		:select({ workspaces = name })
		:withInheritance())
	)

	wks.rootState = rootState
	wks.exportPath = vstudio.sln.filename(wks)

	wks.configs = vstudio.Config.extractAll(wks)
	wks.projects = vstudio.Project.extractAll(wks)

	return wks
end


---
-- Export the contents of a workspace to a Visual Studio `.sln` solution file.
---

function Workspace.export(self)
	premake.export(self, self.exportPath, vstudio.sln.export)

	local projects = self.projects
	for i = 1, #projects do
		projects[i]:export()
	end
end


return Workspace
