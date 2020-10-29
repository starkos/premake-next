local vstudio = require('vstudio')
local vcxproj = vstudio.vcxproj

local VsVcxRootNamespaceTests = test.declare('VsVcxRootNamespaceTests', 'vstudio')


function VsVcxRootNamespaceTests.isSetToProjectName()
	workspace('MyWorkspace', function ()
		project('ProjectA')
	end)

	local prj = vstudio.extractWorkspaces()[1].projects[1]
	vcxproj.rootNamespace(prj)

	test.capture [[
<RootNamespace>ProjectA</RootNamespace>
	]]
end
