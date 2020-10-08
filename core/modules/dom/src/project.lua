local State = require('state')

local Project = declareType('Project', State)


function Project.extractAll(state, inherit)
	local projects = {}

	local names = state.projects
	for i = 1, #names do
		projects[i] = Project.new(state, names[i], inherit)
	end

	return projects
end


function Project.new(state, name, inherit)
	local prj = State.select(state, { projects = name }, inherit)

	prj.name = name
	prj.filename = prj.filename or name
	prj.location = prj.location or os.getCwd()

	return instantiateType(Project, prj)
end


return Project
