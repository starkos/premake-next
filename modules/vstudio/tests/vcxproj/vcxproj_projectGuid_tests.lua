local vstudio = require('vstudio')
local vcxproj = vstudio.vcxproj

local VsVcxProjectGuidTests = test.declare('VsVcxProjectGuidTests', 'vstudio')


function VsVcxProjectGuidTests.isSetFromProjectName()
	workspace('MyWorkspace', function ()
		project('ProjectA')
	end)

	local prj = vstudio.extractWorkspaces()[1].projects[1]
	vcxproj.projectGuid(prj)

	test.capture [[
<ProjectGuid>{1DB858A2-0985-B3AD-329E-A1551ECAE83B}</ProjectGuid>
	]]
end
