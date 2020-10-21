local premake = require('premake')
local Project = require('dom').Project

local DomProjectTests = test.declare('DomProjectTests', 'dom')


function DomProjectTests.new_setsName()
	project('MyProject')
	local prj = Project.new(premake.select(), 'MyProject')
	test.isEqual('MyProject', prj.name)
end


function DomProjectTests.new_setsFilename()
	project('MyProject')
	local prj = Project.new(premake.select(), 'MyProject')
	test.isEqual('MyProject', prj.filename)
end


function DomProjectTests.new_setsLocation()
	project('MyProject')
	local prj = Project.new(premake.select(), 'MyProject')
	test.isEqual(_SCRIPT_DIR, prj.location)
end
