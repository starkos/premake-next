local State = require('state')

local Project = declareType('Project', State)


function Project.new(name, state)
	local prj = instantiateType(Project, state)

	prj.name = name
	prj.filename = prj.filename or name
	prj.location = prj.location or prj.baseDir or os.getCwd()

	return prj
end


return Project
