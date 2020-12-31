local premake = require('premake')
local vstudio = require('vstudio')

local vcxproj = vstudio.vcxproj

local VsVcxProjectGuidTests = test.declare('VsVcxProjectGuidTests', 'vstudio')


function VsVcxProjectGuidTests.isSetFromProjectName()
	workspace('MyWorkspace', function ()
		project('ProjectA')
	end)

	local wks = vstudio.Workspace.extract(premake.newState(), 'MyWorkspace')
	local prj = wks.projects[1]

	vcxproj.projectGuid(prj)

	test.capture [[
<ProjectGuid>{1DB858A2-0985-B3AD-329E-A1551ECAE83B}</ProjectGuid>
	]]
end
