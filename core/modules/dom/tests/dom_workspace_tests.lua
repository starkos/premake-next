local premake = require('premake')
local Workspace = require('dom').Workspace

local DomWorkspaceTests = test.declare('DomWorkspaceTests', 'dom')


local _wks

function DomWorkspaceTests.setup()
	workspace('MyWorkspace')

	_wks = Workspace.new(premake.newState():select({ workspaces = 'MyWorkspace' }))
end


function DomWorkspaceTests.new_setsName()
	test.isEqual('MyWorkspace', _wks.name)
end


function DomWorkspaceTests.new_setsFilename()
	test.isEqual('MyWorkspace', _wks.filename)
end


function DomWorkspaceTests.new_setsLocation()
	test.isEqual(_SCRIPT_DIR, _wks.location)
end
