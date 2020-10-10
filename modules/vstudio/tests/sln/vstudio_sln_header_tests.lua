local vstudio = require('vstudio')
local sln = vstudio.sln

local SlnHeaderTests = test.declare('vstudio_sln_header')


function SlnHeaderTests.on2015()
	vstudio.setTargetVersion(2015)

	sln.header()

	test.capture [[
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio 14
	]]
end
