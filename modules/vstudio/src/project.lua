local Dom = require('dom')
local premake = require('premake')

local vstudio = select(1, ...)

local project = {}


function project.extract(wks, name)
	local prj = Dom.Project.new(wks:select({ projects = name })
		:include(wks.global)
		:withInheritance())

	prj.workspace = wks
	prj.exportPath = vstudio.vcxproj.filename(prj)
	prj.uuid = prj.uuid or os.uuid(prj.name)

	return prj
end


function project.export(prj)
	premake.export(prj, prj.exportPath, vstudio.vcxproj.export)
end


return project
