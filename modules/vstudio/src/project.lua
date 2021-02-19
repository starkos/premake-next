---
-- Visual Studio helper methods for projects.
---

local dom = require('dom')
local path = require('path')
local premake = require('premake')

local vstudio = select(1, ...)

local Project = declareType('Project', dom.Project)


---
-- Extract and return a list of all projects in a workspace.
---

function Project.extractAll(wks)
	local projects = {}

	local names = wks.projects
	for i = 1, #names do
		projects[i] = Project.extract(wks, names[i])
	end

	return projects
end


---
-- Extract a project state instance from a workspace state.
--
-- @param wks
--    The workspace state instance.
-- @param name
--    The name of the project to extract.
-- @returns
--    The corresponding project object.
---

function Project.extract(wks, name)
	local prj = instantiateType(Project, dom.Project.new(wks
		:select({ projects = name })
		:include(wks.rootState)
		:withInheritance())
	)

	prj.rootState = wks.rootState
	prj.workspace = wks

	prj.exportPath = vstudio.vcxproj.filename(prj)
	prj.baseDirectory = path.getDirectory(prj.exportPath)
	prj.uuid = prj.uuid or os.uuid(prj.name)

	prj.configs = vstudio.Config.extractAll(prj)

	return prj
end


---
-- Export the contents of a project to a Visual Studio `project file.
---

function Project.export(self)
	-- TODO: branch by project type; only supporting .vcxproj at the moment
	vstudio.vcxproj.export(self)
end


return Project
