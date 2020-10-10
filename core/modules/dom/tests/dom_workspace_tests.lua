local premake = require('premake')
local Workspace = require('dom').Workspace

local DomWorkspaceTests = test.declare('dom_workspace')


function DomWorkspaceTests.new_setsName()
	workspace('MyWorkspace')
	local wks = Workspace.new(premake.select(), 'MyWorkspace')
	test.isEqual('MyWorkspace', wks.name)
end


function DomWorkspaceTests.new_setsFilename()
	workspace('MyWorkspace')
	local wks = Workspace.new(premake.select(), 'MyWorkspace')
	test.isEqual('MyWorkspace', wks.filename)
end


function DomWorkspaceTests.new_setsLocation()
	workspace('MyWorkspace')
	local wks = Workspace.new(premake.select(), 'MyWorkspace')
	test.isEqual(_SCRIPT_DIR, wks.location)
end
