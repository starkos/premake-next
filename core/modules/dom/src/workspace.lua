local State = require('state')

local Workspace = declareType('Workspace', State)


function Workspace.extractAll(state, inherit)
	local workspaces = {}

	local names = state.workspaces
	for i = 1, #names do
		workspaces[i] = Workspace.new(state, names[i], inherit)
	end

	return workspaces
end


function Workspace.new(state, name, inherit)
	local wks = State.select(state, { workspaces = name }, inherit)

	wks.name = name
	wks.filename = wks.filename or name
	wks.location = wks.location or os.getCwd()

	return instantiateType(Workspace, wks)
end


return Workspace
