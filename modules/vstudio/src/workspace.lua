local premake = require('premake')

local vstudio = select(1, ...)

local workspace = {}


function workspace.prepare(wks)
	wks.exportPath = vstudio.sln.filename(wks)
end


function workspace.export(wks)
	premake.export(wks, wks.exportPath, vstudio.sln.export)
end


return workspace
