local premake = require('premake')
local Project = require('dom').Project

local DomProjectTests = test.declare('DomProjectTests', 'dom')


local _prj

function DomProjectTests.setup()
	project('MyProject')

	_prj = Project.new('MyProject', premake.newState():select({ projects = 'MyProject' }))
end


function DomProjectTests.new_setsName()
	test.isEqual('MyProject', _prj.name)
end


function DomProjectTests.new_setsFilename()
	test.isEqual('MyProject', _prj.filename)
end


function DomProjectTests.new_setsLocation()
	test.isEqual(_SCRIPT_DIR, _prj.location)
end
