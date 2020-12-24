local State = require('state')

local Workspace = declareType('Workspace', State)


function Workspace.new(state)
	local wks = instantiateType(Workspace, state)

	local name = state.workspaces[1]

	wks.name = name
	wks.filename = wks.filename or name
	wks.location = wks.location or wks.baseDir or os.getCwd()

	return wks
end


return Workspace
