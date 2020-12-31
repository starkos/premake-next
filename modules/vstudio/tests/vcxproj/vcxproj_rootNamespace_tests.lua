local premake = require('premake')
local vstudio = require('vstudio')

local vcxproj = vstudio.vcxproj

local VsVcxRootNamespaceTests = test.declare('VsVcxRootNamespaceTests', 'vstudio')


function VsVcxRootNamespaceTests.isSetToProjectName()
	workspace('MyWorkspace', function ()
		project('ProjectA')
	end)

	local wks = vstudio.Workspace.extract(premake.newState(), 'MyWorkspace')
	local prj = wks.projects[1]
	vcxproj.rootNamespace(prj)

	test.capture [[
<RootNamespace>ProjectA</RootNamespace>
	]]
end
