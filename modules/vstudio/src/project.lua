local premake = require('premake')

local vstudio = select(1, ...)

local project = {}


function project.prepare(prj)
	prj.exportPath = vstudio.vcxproj.filename(prj)
	prj.uuid = prj.uuid or os.uuid(prj.name)
end


function project.export(prj)
	premake.export(prj, prj.exportPath, vstudio.vcxproj.export)
end


return project
